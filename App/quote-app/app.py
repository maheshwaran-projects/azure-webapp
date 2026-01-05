from flask import Flask, jsonify
import pyodbc
import os
import requests
import struct
import traceback
import logging
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Environment variables with defaults for private endpoint
server = os.environ.get("SQL_SERVER", "sql-quote-05d126e2.privatelink.database.windows.net")
database = os.environ.get("SQL_DATABASE", "quotedb")
app_name = os.environ.get("APP_NAME", "quote-app")

logger.info(f"Application '{app_name}' starting with:")
logger.info(f"  SQL Server: {server}")
logger.info(f"  Database: {database}")

# Cache for access token (optional improvement)
_token_cache = {"token": None, "expires_at": None}

def get_access_token():
    """Get access token from Managed Identity with caching"""
    # Check cache first (optional optimization)
    if _token_cache["token"] and _token_cache["expires_at"]:
        if datetime.now() < _token_cache["expires_at"]:
            logger.debug("Using cached access token")
            return _token_cache["token"]

    url = "http://169.254.169.254/metadata/identity/oauth2/token"
    params = {
        "api-version": "2018-02-01",
        "resource": "https://database.windows.net/"
    }
    headers = {"Metadata": "true"}

    try:
        response = requests.get(url, headers=headers, params=params, timeout=10)
        response.raise_for_status()
        token_data = response.json()
        access_token = token_data["access_token"]

        # Cache token (expire 5 minutes before actual expiration)
        expires_in = int(token_data.get("expires_in", 3599))  # Convert to int
        _token_cache["token"] = access_token
        _token_cache["expires_at"] = datetime.now() + timedelta(seconds=expires_in - 300)

        logger.info("Successfully acquired Managed Identity token")
        return access_token

    except requests.exceptions.Timeout:
        logger.error("Timeout getting access token from IMDS")
        raise Exception("Timeout accessing Managed Identity service")
    except requests.exceptions.ConnectionError:
        logger.error("Cannot connect to IMDS endpoint")
        raise Exception("Managed Identity service unavailable")
    except Exception as e:
        logger.error(f"Failed to get access token: {str(e)}")
        raise

def get_db_connection():
    """Create database connection with Managed Identity"""
    try:
        access_token = get_access_token()

        # Encode + pack token (REQUIRED for ODBC)
        token_bytes = access_token.encode("utf-16-le")
        token_struct = struct.pack(
            f"<I{len(token_bytes)}s",
            len(token_bytes),
            token_bytes
        )

        # CRITICAL FIXES APPLIED:
        # 1. TrustServerCertificate=yes for private endpoint SSL mismatch
        # 2. Proper connection timeout
        # 3. Encrypt=yes for security
        conn_str = (
            "DRIVER={ODBC Driver 18 for SQL Server};"
            f"SERVER=tcp:{server},1433;"
            f"DATABASE={database};"
            "Encrypt=yes;"
            "TrustServerCertificate=yes;"  # Required for private endpoint
            "Connection Timeout=30;"
        )

        logger.debug(f"Connecting with: {conn_str[:80]}...")

        # Connect using token in attrs_before
        conn = pyodbc.connect(
            conn_str,
            attrs_before={1256: token_struct}
        )

        logger.info("Database connection established successfully")
        return conn

    except pyodbc.Error as e:
        logger.error(f"Database connection error: {e}")

        # Enhanced error diagnostics
        error_info = {
            "error": str(e),
            "sqlstate": getattr(e, 'sqlstate', 'N/A'),
            "error_code": getattr(e, 'error_code', 'N/A'),
            "server": server,
            "database": database
        }

        # Common error patterns
        if "certificate verify failed" in str(e):
            error_info["suggestion"] = "SSL certificate validation failed. TrustServerCertificate=yes is set."
        elif "Login failed" in str(e) or "authentication" in str(e).lower():
            error_info["suggestion"] = "Managed Identity may not have SQL permissions. Check Azure AD admin assignment."
        elif "denied because Deny Public Network Access" in str(e):
            error_info["suggestion"] = "SQL Server has public access disabled. Ensure using private endpoint."

        raise Exception(f"Database connection failed: {error_info}")

    except Exception as e:
        logger.error(f"Unexpected connection error: {e}")
        raise

@app.route("/")
def get_quote():
    """Get random quote from database"""
    try:
        start_time = datetime.now()
        conn = get_db_connection()
        cursor = conn.cursor()

        # Get random quote
        cursor.execute("SELECT TOP 1 quote, author FROM quotes ORDER BY NEWID()")
        row = cursor.fetchone()
        conn.close()

        response_time = (datetime.now() - start_time).total_seconds() * 1000

        if row:
            logger.info(f"Quote retrieved in {response_time:.0f}ms")
            return jsonify({
                row[1]: row[0],  # Author as key, quote as value
                "response_time_ms": response_time
            })
        else:
            logger.warning("No quotes found in database")
            return jsonify({
                "error": "No quotes found",
                "message": "The quotes table is empty"
            }), 404

    except pyodbc.Error as e:
        logger.error(f"Database query error: {e}")
        error_details = {
            "error": "Database error",
            "message": str(e),
            "sqlstate": getattr(e, 'sqlstate', 'N/A'),
            "error_code": getattr(e, 'error_code', 'N/A'),
            "timestamp": datetime.now().isoformat()
        }
        return jsonify(error_details), 500

    except Exception as e:
        logger.error(f"Application error: {e}")
        error_details = {
            "error": "Application error",
            "message": str(e),
            "timestamp": datetime.now().isoformat()
        }
        return jsonify(error_details), 500

@app.route("/health")
def health():
    """Comprehensive health check endpoint"""
    try:
        # Test token acquisition
        token_obtained = False
        try:
            get_access_token()
            token_obtained = True
        except Exception as e:
            logger.warning(f"Token acquisition in health check failed: {e}")

        # Test database connection
        db_connected = False
        if token_obtained:
            try:
                conn = get_db_connection()
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                conn.close()
                db_connected = True
            except Exception as e:
                logger.warning(f"Database connection in health check failed: {e}")

        status = "healthy" if token_obtained and db_connected else "degraded"

        return jsonify({
            "status": status,
            "service": app_name,
            "components": {
                "managed_identity": "healthy" if token_obtained else "unhealthy",
                "database": "healthy" if db_connected else "unhealthy"
            },
            "details": {
                "sql_server": server,
                "database": database,
                "timestamp": datetime.now().isoformat()
            }
        }), 200 if status == "healthy" else 503

    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            "status": "unhealthy",
            "service": app_name,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }), 503

@app.route("/test/connection")
def test_connection():
    """Detailed connection test endpoint"""
    try:
        # Test 1: Token acquisition
        token_start = datetime.now()
        token = get_access_token()
        token_time = (datetime.now() - token_start).total_seconds() * 1000

        # Test 2: Database connection
        db_start = datetime.now()
        conn = get_db_connection()
        cursor = conn.cursor()

        # Test 3: Simple query
        cursor.execute("SELECT @@VERSION")
        version_row = cursor.fetchone()
        sql_version = version_row[0] if version_row else "N/A"

        # Test 4: Quotes count
        cursor.execute("SELECT COUNT(*) FROM quotes")
        count_row = cursor.fetchone()
        quote_count = count_row[0] if count_row else 0

        # Test 5: Sample data
        cursor.execute("SELECT TOP 1 quote, author FROM quotes")
        sample_row = cursor.fetchone()

        conn.close()
        db_time = (datetime.now() - db_start).total_seconds() * 1000

        return jsonify({
            "status": "success",
            "tests": {
                "token_acquisition": {
                    "status": "passed",
                    "time_ms": token_time,
                    "token_length": len(token)
                },
                "database_connection": {
                    "status": "passed",
                    "time_ms": db_time,
                    "server": server,
                    "database": database
                },
                "query_execution": {
                    "status": "passed",
                    "sql_version": sql_version[:100] + "..." if len(sql_version) > 100 else sql_version,
                    "quote_count": quote_count,
                    "sample_quote": {
                        "quote": sample_row[0][:100] + "..." if sample_row and len(sample_row[0]) > 100 else (sample_row[0] if sample_row else None),
                        "author": sample_row[1] if sample_row else None
                    } if sample_row else None
                }
            },
            "connection_details": {
                "endpoint_type": "private" if "privatelink" in server else "public",
                "ssl_validation": "bypassed" if "TrustServerCertificate=yes" in locals().get('conn_str', '') else "enabled"
            }
        })

    except Exception as e:
        logger.error(f"Connection test failed: {e}")
        return jsonify({
            "status": "failed",
            "error": str(e),
            "traceback": traceback.format_exc()[:500] if app.debug else None
        }), 500

@app.route("/metrics")
def metrics():
    """Simple metrics endpoint (can be extended with Prometheus)"""
    return jsonify({
        "service": app_name,
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "endpoints": ["/", "/health", "/test/connection", "/metrics"]
    })

# ============================================
# KUBERNETES PROBE ENDPOINTS
# ============================================

@app.route("/healthz")
def healthz():
    """Kubernetes liveness probe endpoint (lightweight)"""
    try:
        # Quick check - just verify Flask is running
        return jsonify({
            "status": "healthy",
            "service": app_name,
            "endpoint": "liveness",
            "timestamp": datetime.now().isoformat()
        }), 200
    except Exception as e:
        return jsonify({
            "status": "unhealthy",
            "error": str(e),
            "endpoint": "liveness"
        }), 500

@app.route("/ready")
def ready():
    """Kubernetes readiness probe endpoint (checks database)"""
    try:
        # Check database connection for readiness
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        conn.close()

        return jsonify({
            "status": "ready",
            "service": app_name,
            "database": "connected",
            "endpoint": "readiness",
            "timestamp": datetime.now().isoformat()
        }), 200
    except Exception as e:
        logger.warning(f"Readiness probe failed: {e}")
        return jsonify({
            "status": "not_ready",
            "service": app_name,
            "database": "disconnected",
            "error": str(e),
            "endpoint": "readiness"
        }), 503

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Not found",
        "message": "The requested endpoint does not exist",
        "available_endpoints": ["/", "/health", "/test/connection", "/metrics", "/healthz", "/ready"]
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "error": "Internal server error",
        "message": "An unexpected error occurred",
        "timestamp": datetime.now().isoformat()
    }), 500

if __name__ == "__main__":
    # Production settings
    debug_mode = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    port = int(os.environ.get("PORT", 8080))

    logger.info(f"Starting Flask app on port {port} (debug={debug_mode})")

    # Production server (use gunicorn in production)
    app.run(
        host="0.0.0.0",
        port=port,
        debug=debug_mode,
        threaded=True  # Better for production
    )
