1. Project Overview:This project involves the containerization, debugging, and automated deployment of a real-time chat application. It configured infrastructure and transform it into a production-ready environment using Docker, Nginx, and GitHub Actions.
2. Architecture Diagram:The application follows a standard production-style reverse proxy architecture.
Public IP: The entry point for all external traffic.
NGINX (Reverse Proxy): Handles incoming HTTP traffic, serves static frontend files, and manages WebSocket handshakes.
WebSocket Backend: A containerized Node.js/Python application handling real-time messaging.
3. Docker Container Setup:The system is orchestrated using Docker Compose to ensure all services start in the correct order with the necessary environment variables.Restart Policy: All containers are configured with restart: always to ensure high availability if the server or process crashes.
4. Docker Networking:A dedicated bridge network is used to allow internal communication between the Nginx container and the Backend container.The Backend is not exposed directly to the public internet; it is only reachable via the Nginx proxy, enhancing security. 
5. Nginx & WebSocket Configuration:To successfully proxy WebSockets, Nginx must explicitly handle the connection "Upgrade". The configuration includes:
Reverse Proxy: Routing traffic from port 80 to the internal Docker backend.
Header Management: Setting Upgrade $http_upgrade and Connection "upgrade" to allow the persistent WebSocket handshake to succeed.
Frontend Hosting: Nginx serves the static HTML/JS files directly to the user's browser.
6. CI/CD Pipeline:The deployment is fully automated using GitHub Actions.
Trigger: On every push to the main branch.
SSH Connection: The runner connects to the Cloud VM (e.g., AWS EC2 or Oracle Cloud).
Deployment: The pipeline pulls the latest code, rebuilds the images, and restarts the containers using docker-compose up -d --build.
7. Debugging: Issues Found & Fixes:
- Issue Identified: Containers couldn't talk.
   Root Cause     : Missing shared Docker network
   Fix Applied    : Added a custom bridge network in docker-compose.yml
- Issue Identified: WS Connection Failed
   Root Cause     : Nginx missing Upgrade headers
   Fix Applied    : Added proxy_set_header Upgrade in nginx.conf
- Issue Identified: 404 on Frontend
   Root Cause     : Wrong file path in Nginx
   Fix Applied    : Updated the root directive to point to the correct folder
- Issue Identified: App Crash on Boot
   Root Cause     : Missing dependencies in Dockerfile
   Fix Applied    : Updated Dockerfile to include all necessary build steps.
8. Deployment Steps:To run this project locally or on a new server:
- Clone the repo: git clone https://github.com/Akanksha24999/devops-assignment.git
- Navigate to directory: cd devops-assignment
- Start the system: docker-compose up -d --build.
- Access the app: Open http://13.201.42.158 in your browser.
9. Live Public IP: http://13.201.42.158
<<<<<<< HEAD
10.  I added terraform automation as a bonus additional step. The Terraform configuration in this project uses the following components to automate the AWS infrastructure:
The Terraform configuration in this project uses the following components to automate the AWS infrastructure:
- Infrastructure as Code (IaC) with AWS: It uses the AWS provider to provision resources like security groups for the load       balancer within a specified region.
- Auto Scaling for High Availability: An Auto Scaling Group is configured to maintain instances, ensuring the application can handle traffic and recover from failures.
- Automated Traffic Routing: An Application Load Balancer is used to distribute public traffic to instances, while a Target Group monitors their health to ensure requests are only sent to working servers.
- Automated Application Deployment: A Launch Template uses a "user data" script to automatically update the server, pull the latest code from GitHub, and start the application using Docker Compose upon boot.
