# Java CI/CD Demo

- Maven app
- Jenkins Pipeline driven by GitHub Integration
- Docker image build and push to Nexus
- Auto-versioning of the application and
- Committing local changes back to the remote repository

This is the flow: 
Developer pushes → Jenkins → Maven build → Docker build → Nexus push → Update VERSION.txt.
