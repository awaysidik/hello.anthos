FROM madhavimorla/tibco-bwce:latest
#FROM gcr.io/anthos-alpha-5929/tibco-base-image
LABEL maintainer="Vijay Nalawade <vnalawad@tibco.com>"
ADD hello.service.application/target/hello.service.application_1.0.0.ear /
EXPOSE 8080
EXPOSE 8090
