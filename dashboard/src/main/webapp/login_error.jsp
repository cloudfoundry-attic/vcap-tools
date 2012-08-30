<%@ page import="org.springframework.security.web.WebAttributes"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>

<html>
<body>

<h1>Sample Error Page</h1>

<p>
    There was a problem logging you in.  Don't panic.
</p>
<%
    if (request.getAttribute(WebAttributes.ACCESS_DENIED_403) != null) {
%>
<div class="error">
    <p>
        <%= request.getAttribute(WebAttributes.ACCESS_DENIED_403) %>
    </p>
</div>
<%
    }
%>
</body>
</html>
