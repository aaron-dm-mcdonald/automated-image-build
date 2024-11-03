from flask import Flask, render_template_string
import requests
import socket
import os  # Import os to access environment variables

app = Flask(__name__)

@app.route('/')
def index():
    # Google Cloud Metadata server base URL and header
    METADATA_URL = "http://metadata.google.internal/computeMetadata/v1"
    METADATA_FLAVOR_HEADER = {"Metadata-Flavor": "Google"}

    # Fetch instance metadata
    local_ipv4 = requests.get(f"{METADATA_URL}/instance/network-interfaces/0/ip", headers=METADATA_FLAVOR_HEADER).text
    zone = requests.get(f"{METADATA_URL}/instance/zone", headers=METADATA_FLAVOR_HEADER).text
    project_id = requests.get(f"{METADATA_URL}/project/project-id", headers=METADATA_FLAVOR_HEADER).text
    network_tags = requests.get(f"{METADATA_URL}/instance/tags", headers=METADATA_FLAVOR_HEADER).text
    hostname = socket.getfqdn()  # Get the fully qualified domain name

    # HTML template to render instance details
    html_content = """
    <html><body>
    <h2>Welcome to your custom website.</h2>
    <h3>Created with a Flask application!</h3>
    <p><b>Instance Name:</b> {{ hostname }}</p>
    <p><b>Instance Private IP Address:</b> {{ local_ipv4 }}</p>
    <p><b>Zone:</b> {{ zone }}</p>
    <p><b>Project ID:</b> {{ project_id }}</p>
    <p><b>Network Tags:</b> {{ network_tags }}</p>
    </body></html>
    """
    
    # Render the HTML template with instance metadata
    return render_template_string(html_content, hostname=hostname, local_ipv4=local_ipv4, zone=zone, project_id=project_id, network_tags=network_tags)

if __name__ == "__main__":
    # Use the PORT environment variable, default to 8080 if not set
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
