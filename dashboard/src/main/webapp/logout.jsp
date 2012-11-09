<%@ page import="org.springframework.security.web.WebAttributes" %>
<%@ page import="org.springframework.security.access.AccessDeniedException" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<html>
<head><title>Dashboard Logout</title></head>
<body>

<%
    if (request.getParameter("access_denied") != null && "true".equals(request.getParameter("access_denied").toLowerCase())) {
%>
<div class="error">
    <h3>
        <p>
            Access is denied
        </p>
    </h3>
    <p>
        Oops! It looks like you don't have the necessary authorizations to access this resource.
        <br />
        <b>Please contact your system administrator for access permissions before trying again!</b> <br />
    </p>
</div>
<%
    }
%>

<div class="logout">
    <p>
        You have been logged out of Dashboard,
        click <a href="<%= request.getAttribute("uaaUrl") + "/logout.do" %>">here</a> to logout of CloudFoundry too.
    </p>
</div>

</body>
</html>
