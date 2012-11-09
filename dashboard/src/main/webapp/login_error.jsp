<%@ page import="org.springframework.security.web.WebAttributes" %>
<%@ page import="org.springframework.security.access.AccessDeniedException" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<html>
<head><title>Access Denied</title></head>
<body>

<%
    if (request.getAttribute(WebAttributes.ACCESS_DENIED_403) != null) {
%>
<div class="error">
    <h3>
        <p>
            <%= ((AccessDeniedException)request.getAttribute(WebAttributes.ACCESS_DENIED_403)).getMessage() %>
        </p>
    </h3>
    <p>
        Oops! It looks like you don't have the necessary authorizations to access this resource. Click <a href="logout">here</a> to logout of Dashboard.
        <br />
        <b>Please contact your system administrator for access permissions before trying again!</b> <br />
    </p>
</div>
<%
    }
%>

</body>
</html>
