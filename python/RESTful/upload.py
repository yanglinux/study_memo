from flask import Flask, jsonify, abort, make_response,request
from werkzeug import secure_filename
import os

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload():
    the_file = request.files['file']
    save_path = "/opt/test/upload/" + the_file.filename
    the_file.save(save_path)
    #print request.form['other_data']

    shell_file = '/opt/test/classifier'

    return_val = "Restricted" if os.system(shell_file + " " + save_path) else "General Audiences"

    result = {
        "result":return_val,
        "data":{
            "FileName":the_file.filename
        }
    }

    return make_response(jsonify(result))

@app.errorhandler(404)
def not_found(error):
    return make_response(jsonify({'error': 'Not found'}), 404)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
