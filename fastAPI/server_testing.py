import csv
import json

csv_file_path = '../mobile_app/assets/modelData.csv'

# Output file to store the generated curl commands
output_file_path = 'curl_commands.txt'

# Read the CSV file
with open(csv_file_path, newline='') as csvfile:
    reader = csv.reader(csvfile)
    
    # Prepare the list of curl commands
    curl_commands = []

    for row in reader:
        if len(row) == 120:  # Make sure each row contains exactly 120 floats
            # Convert the row to a list of floats
            input_data = [float(value) for value in row]
            
            # Create the curl command
            curl_command = f"""
curl -X POST 'http://127.0.0.1:8000/predict/' \
  -H 'Content-Type: application/json' \
  -d '{json.dumps({"input": input_data})}'
"""
            curl_commands.append(curl_command)

# Write all curl commands to a text file
with open(output_file_path, 'w') as outfile:
    outfile.write("\n".join(curl_commands))
