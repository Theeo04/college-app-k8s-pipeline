
# Kubernetes Cluster on AWS Instances with GitLab CI/CD and Grafana Monitoring Implementation

This project automates application deployment on a Kubernetes cluster hosted on AWS EC2 instances. It includes a CI/CD pipeline for testing code with SonarQube, automatic image creation, and deployment, with integrated monitoring using Prometheus and Grafana for real-time metrics and logs.

---
#### The AWS instances have been stopped to manage billing costs, also I need to purchase more minutes for the GitLab runners
---

## Used Technologies:

- **Kubernetes**: Container orchestration platform for automating application deployment, scaling, and management.
- **kubeadm**: Tool for easily deploying and managing Kubernetes clusters, used to set up the cluster in this project.
- **Python**: Programming language used to develop the application.
- **AWS EC2**: Cloud computing service providing scalable virtual servers for hosting the Kubernetes cluster.
- **GitLab CI/CD**: Continuous Integration and Continuous Deployment tool for automating testing, building, and deploying applications.
- **SonarQube**: Code quality and security analysis tool integrated into the CI/CD pipeline for automated code testing.
- **Docker and Dockerhub**: Containerization platform used to create and manage application images for deployment.
- **Prometheus**: Monitoring and alerting toolkit used to collect and store metrics from the Kubernetes cluster.
- **Grafana**: Visualization tool for creating dashboards to monitor application metrics and logs in real-time.

# Now Let's Talk in Detail About the Project

## 1. Import the Source Code of the Project and Dockerize It

- The source code of the project can be found at: [College-ERP GitHub Repository](https://github.com/samarth-p/College-ERP).
- Install Docker on your machine, create a container using a Dockerfile, and upload the image to Docker Hub.
- The command used to run the app and allow access from any external device is:

    ```bash
    manage.py runserver 0.0.0.0:8000
    ```

So, `0.0.0.0` is a special IP address that refers to all IP addresses on the local machine. It is commonly used for listening for incoming connections across all network interfaces or defining default routes.

 - Connection to container using EC2 instance public IP:
![App Screenshot](doc-imgs/connect-to-pod-using-publicip.png)


## 2. Create the Kubernetes Cluster and Add SonarQube Tests

- **Create 3 EC2 Instances**: 
  - Set up 1 Master Node and 2 Worker Nodes, each with a public IP.
  
- **Configure Security Group**: 
  - Allow inbound access on NodePort services and ensure Prometheus, Grafana, and SonarQube servers can communicate with the cluster.

- **Connect the Nodes**: 
  - Use **kubeadm** to establish the connection between the nodes. *(Tutorials can be found in the footer of this README file)*.

![Instances EC2](doc-imgs/aws-instances.png)
![Cluster Flowchart](doc-imgs/cluster-chart.png)
![Connected Nodes](doc-imgs/connecting-node2-to-cluster.png)

- **Deploy Applications with Helm Chart**: 
  - After creating the cluster as designed in the flowchart, deploy the applications using **Helm Chart** on the Master Node. For installation instructions, refer to the [Helm Installation Documentation](https://helm.sh/docs/intro/install/).

  **Helm Charts** simplify the deployment and management of applications on Kubernetes by providing a reusable way to define, install, and upgrade complex applications.
---
- **Install the Helm Chart**: 
  - Run the command:
    ```bash
    helm install collegeapp helm-chart
    ```

  - The following actions occur:
    1. Helm takes the helm-chart from the specified directory.
    2. It processes the templates and fills in configurations from `values.yaml` or command-line overrides.
    3. It communicates with the Kubernetes API to create the necessary resources (like Pods, Services, Deployments, etc.) defined in the chart.
    4. It names this deployment instance "collegeapp."

- **Retrieve the Application URL**: 
  - Execute the following commands:
    ```bash
    export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services collegeapp-helm-chart)
    export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
    echo http://$NODE_IP:$NODE_PORT
    ```

- **Check Application Status**: 
  - Use the command:
    ```bash
    kubectl get pods
    ```
    - Sample output:
    ```
    NAME                                    READY   STATUS    RESTARTS   AGE
    collegeapp-helm-chart-547f55cbc-rmqrr   1/1     Running   0          38s
    ```

![Get services](doc-imgs/succesfull-conn-with-kubeadm.png)

## Note
- If you change `values.yaml` or any configurations, run the following command to upgrade:
  ```bash
  helm upgrade collegeapp helm-chart/

- **Access via NodePort (targetPort 8000, port 8000)** using the following URLs:
  - **Node 1**: [http://54.165.23.95:32563](http://54.165.23.95:32563)
  - **Node 2**: [http://54.89.252.144:32563](http://54.89.252.144:32563)

![Services](doc-imgs/get-svc-nodeport.png)

  ## Use SonarQube

- **Overview**: 
  - SonarQube is an open-source platform for continuous inspection of code quality. It enables developers and organizations to manage code quality by analyzing and measuring various aspects of the codebase. SonarQube helps identify issues related to code quality, security vulnerabilities, and technical debt.

- **How to Run SonarQube**: 
  - Use the following command to run SonarQube in a Docker container:
    ```bash
    docker run --name sonar -d -p 9000:9000 sonarqube:lts-community
    ```

- **Access SonarQube**: 
  - Visit SonarQube at: 
    ```
    <master-ip>:9000
    ```
    
    - **Credentials**: 
      - Username: `admin`
      - Password: `admin123`

- **Check the Tests**:
![Test Passed](doc-imgs/sonarqube-passed-checks.png)


### 3. Create the Gitlab CI/CD Pipeline:

This document describes the CI/CD pipeline for the **College App** project, which includes SonarQube for code quality checks, Docker image build and push, and deployment to a Kubernetes cluster using Helm - *when a commit is made in main, the pipeline will run*.
The connection to the EC2 master node is facilitated by the **GitLab Runner**.

**The pipeline consists of the following stages:**
 - **sonarqube-check** - runs code quality analysis using SonarQube.
 - **build** - build a new image for every new commit in main
 - **push** - update the new Docker image on Dockerhub
 - **deploy** - Deploys the Docker image to the Kubernetes cluster using Helm.

 ```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy to Kubernetes Cluster using Helm-Chart"
    - helm upgrade collegeapp ./helm-chart --set image.repository=$DOCKER_USERNAME/$DOCKER_IMAGE --set image.tag=latest
  tags:
    - master-runner 
  only:
    - main
 ```

 **NOTE**:
 - The tags section (e.g., tags: - master-runner) specifies which GitLab Runner will execute the job.
 - It ensures that the job runs on a runner with the appropriate resources or permissions, especially for specialized tasks like deployments.

**How it looks:**

![Pipeline](doc-imgs/pipiline-gitlab.png)

### 4. Install Prometheus and Grafana for monitoring our cluster - using helm-chart
*Installation guide in the footer of the documentation*

 - After the installation steps and run the commands displayed on CL - *for getting Grafana credentials: admin/<password>* - introduce on Grafana website the URL where the Prometheus server is running and its port ( ex: <PUBLIC-NODE-IP>:30900, my case: http://34.207.192.136:30900 and http://54.175.177.172:30900 ) and create a dashboard.

  - *Dashboard:*

![Dashboard](doc-imgs/prometheus-dashboard.png)

**Have Fun**: try to scale, and check the Grafana Dashboard: 
```kubectl scale deployment collegeapp-helm-chart --replicas=3 ```

where, *collegeapp-helm-chart* => deployment name: 
```kubectl get deployments```

# Access the application which runs on our Cluster!: 
*http://<IPv4-PUBLIC-ADDRESS>:<NODEPORT-PORT> - dont use https*

![Cluster-Connection](doc-imgs/cluster-connection-from-web.png)
![PublicIP](doc-imgs/image.png)

 **NOTE:** Allow the inbound traffic on NodePort in security groups:

---
### Useful links:
 - **Github Python Code Repo:** https://github.com/samarth-p/College-ERP
 - **kubeadm and Cluster Configuration** https://ansarshaik965.hashnode.dev/kubeadm-installation-guide
 - **Install Helm Chart** https://helm.sh/docs/intro/install/
 - **Install Grafana and Prometheus Server** https://ansarshaik965.hashnode.dev/prometheus-grafana-installation-using-helm-chart
 - **Create an EC2 AWS instance** https://www.youtube.com/watch?v=86Tuwtn3zp0




