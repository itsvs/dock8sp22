import platform
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():
    return f"This code is running on {platform.system()}."

app.run(host="0.0.0.0", port=3000)