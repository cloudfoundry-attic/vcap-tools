package com.cloudfoundry.dashboard.security.oauth;

import org.springframework.security.oauth2.client.OAuth2RestTemplate;
import org.springframework.security.oauth2.provider.authentication.OAuth2AuthenticationProcessingFilter;
import org.springframework.util.Assert;
import org.springframework.web.client.RestTemplate;

import javax.servlet.http.HttpServletRequest;

public class Oauth2AuthenticationFilter extends OAuth2AuthenticationProcessingFilter {

    private RestTemplate restTemplate;

    public void setRestTemplate(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Override
    public void afterPropertiesSet() {
        if (restTemplate != null) {
            Assert.state(restTemplate instanceof OAuth2RestTemplate, "Supply an OAuth2 RestTemplate");
        }
        super.afterPropertiesSet();
    }

    @Override
    protected String parseToken(HttpServletRequest request) {
        // first check for the token in request header or param
        String token = super.parseToken(request);

        // if not present, fetch it from UAA using Auth code flow. Oauth2RestTemplate already does this, so just use it.
        if (token == null && restTemplate != null) {
            token = ((OAuth2RestTemplate)restTemplate).getAccessToken().getValue();
        }
        return token;
    }


}
