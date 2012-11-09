<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<html>
<head><title>Dashboard Logout</title></head>
<body>

<div class="logout">
    <p>
        You have been logged out of Dashboard,
        click <a href="<spring:eval expression="@jspPropertyConfigurer.getProperty('uaa.url')+'/logout.do'" />">here</a> to logout of CloudFoundry too.
    </p>
</div>

</body>
</html>
