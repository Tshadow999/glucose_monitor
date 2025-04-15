import csv
import json

csv_file_path = 'modelData.csv' 

# Output file to store the generated curl commands
output_file_path = 'curl_commands.txt'

# Read the CSV file
with open(csv_file_path, newline='') as csvfile:
    reader = csv.reader(csvfile)
    curl_commands = []

    buffer = []

    for row in reader:
        if len(row) == 120:
            buffer.append([float(value) for value in row])

            if len(buffer) == 3:
                combined_input = buffer[0] + buffer[1] + buffer[2]
                curl_command = f"""
curl -X POST 'http://127.0.0.1:8000/predict/' \\
  -H 'Content-Type: application/json' \\
  -d '{json.dumps({"input": combined_input})}'
"""
                curl_commands.append(curl_command)
                buffer = []  # Clear buffer for next set

# Write all curl commands to a text file
with open(output_file_path, 'w') as outfile:
    outfile.write("\n".join(curl_commands))
