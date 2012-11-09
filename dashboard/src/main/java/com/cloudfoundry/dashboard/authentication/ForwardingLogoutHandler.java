package com.cloudfoundry.dashboard.authentication;

import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Collections;
import java.util.Map;

public class ForwardingLogoutHandler implements LogoutSuccessHandler {

    private String onLogoutPage = "logout.jsp";

    private Map<String, String> logoutPageAttributes = Collections.emptyMap();

    public void setOnLogoutPage(String onLogoutPage) {
        this.onLogoutPage = onLogoutPage;
    }

    public void setLogoutPageAttributes(Map<String, String> logoutPageAttributes) {
        this.logoutPageAttributes = logoutPageAttributes;
    }

    @Override
    public void onLogoutSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
        for (String attr : logoutPageAttributes.keySet()) {
            request.setAttribute(attr, logoutPageAttributes.get(attr));
        }
        // forward to configured page
        RequestDispatcher dispatcher = request.getRequestDispatcher(onLogoutPage);
        dispatcher.forward(request, response);
    }
}
