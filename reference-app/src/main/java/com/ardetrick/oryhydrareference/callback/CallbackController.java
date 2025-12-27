package com.ardetrick.oryhydrareference.callback;

import lombok.AccessLevel;
import lombok.NonNull;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import lombok.val;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

@Slf4j
@Controller
@RequestMapping("/callback")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CallbackController {

    @NonNull CallbackService callbackService;

    @GetMapping
    public ModelAndView handleCallback(
            @RequestParam(value = "code", required = false) String code,
            @RequestParam(value = "state", required = false) String state,
            @RequestParam(value = "scope", required = false) String scope,
            @RequestParam(value = "error", required = false) String error,
            @RequestParam(value = "error_description", required = false) String errorDescription
    ) {
        log.info("Callback received - code: {}, state: {}, scope: {}", 
                code != null ? "present" : "null", state, scope);

        if (error != null) {
            log.warn("OAuth error received: {} - {}", error, errorDescription);
            return new ModelAndView("callback-error")
                    .addObject("error", error)
                    .addObject("errorDescription", errorDescription);
        }

        if (code == null) {
            log.warn("No authorization code received");
            return new ModelAndView("callback-error")
                    .addObject("error", "missing_code")
                    .addObject("errorDescription", "No authorization code was received");
        }

        val callbackResult = callbackService.processCallback(code, state, scope);

        return new ModelAndView("callback")
                .addObject("code", code)
                .addObject("state", state)
                .addObject("scope", scope)
                .addObject("tokenResponse", callbackResult.tokenResponse())
                .addObject("error", callbackResult.error());
    }

}
