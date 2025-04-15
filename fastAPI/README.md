# Cloud Server for Machine Learning Model

Makes your own device act as a cloud, and run the model from said device.

## usage:
    Go into a virtual env:
    source ~/myenv/bin/activate
    Then move into this dir:
    cd glucose_monitor/fastAPI/
    Finally start the server:
    uvicorn server:app --host 0.0.0.0 --port 8000

    Now use uri: 'https://local_ip:8000/predict/'
