from flask import Flask, Response, render_template
import subprocess
import json

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/capture')
def capture():
    def generate():
        process = subprocess.Popen(
            ['tshark', '-i', 'any', '-T', 'json'],
            stdout=subprocess.PIPE,
            universal_newlines=True
        )
        for line in process.stdout:
            yield f"data: {line}\n\n"

    return Response(generate(), mimetype='text/event-stream')