FROM maven:3.8.6-openjdk-17-slim AS build
  COPY src /home/app/src
  COPY pom.xml /home/app
  RUN mvn -f /home/app/pom.xml clean package

  FROM tomcat:10.1-jre17-slim
  COPY --from=build /home/app/target/ROOT.war /usr/local/tomcat/webapps/
  EXPOSE 8080
  CMD ["catalina.sh", "run"]
