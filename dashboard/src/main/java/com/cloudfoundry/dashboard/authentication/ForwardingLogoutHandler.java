package com.cloudfoundry.dashboard.authentication;

import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.LogoutSuccessHandler;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

public class ForwardingLogoutHandler implements LogoutSuccessHandler {

    private String onLogoutPage = "logout.jsp";

    public void setOnLogoutPage(String onLogoutPage) {
        this.onLogoutPage = onLogoutPage;
    }

    @Override
    public void onLogoutSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws IOException, ServletException {
        // forward to configured page
        RequestDispatcher dispatcher = request.getRequestDispatcher(onLogoutPage);
        dispatcher.forward(request, response);
    }
}
