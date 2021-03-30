''' 
ScriptDescription: 歌尔微电子自动更新体温脚本
Author: Microbubu
Date: 2021-02-26
GithubUrl: https://github.com/Microbubu/awesome_scripts/blob/main/python/auto_temperature.py
'''

import requests
import time
import random
from requests_toolbelt import MultipartEncoder

login_url = 'http://got.goermicro.com:8089/got/temperature/login.html'
submit_url = 'http://got.goermicro.com:8089/got/temperature/add.html'
employee_id, employee_name, identity_id = ('0000000', '姓名', '000000')   #工号 中文姓名 省份证后6位
login_params = {
    'loginFlag':'1', 
    'employeeNumber':employee_id, 
    'numId':identity_id
}
session = requests.session()

def login():
    response = session.post(login_url, login_params)
    return response.status_code == 200

def attend():
    attend_params = login_params.copy()
    del attend_params["loginFlag"]
    response = session.post(login_url, attend_params)
    return response.status_code == 200

def submit():
    localtime = time.localtime()
    localdate = "{0}-{1}-{2}".format(localtime.tm_year, str(localtime.tm_mon).zfill(2), str(localtime.tm_mday).zfill(2))
    temperature = 36.0 + random.randint(0, 2) * 0.1 * (1 if random.randint(0, 1) == 0 else -1)
    print(temperature)
    params = {
        'employeeNumber': employee_id,
        'name': employee_name,
        'redFlag': '',
        'HBFlag': '',
        'JGFlag': '',
        'deptManager': '',
        'addSpecialArea': '',
        'surveyDate': localdate,
        'morning': str(temperature),
        'normal': '1',
        'remark': '',
        'nowAddress': '',
        'nowAddressRemark': ''
    }
    encode = MultipartEncoder(fields = params, boundary='----WebKitFormBoundaryC8zkCwxBagpzDeNd')
    session.headers["Content-Type"] = encode.content_type
    response = session.post(submit_url, data = encode)
    return response.status_code == 200

def retry3times_if_failed(function):
    call_times = 0
    while(True):
        if call_times >= 3:
            break
        elif function():
            return True
        else:
            call_times += 1
    return False

if __name__ == "__main__":
    funcs = [login, attend, submit]
    for func in funcs:
        if not retry3times_if_failed(func):
            break
    session.close()