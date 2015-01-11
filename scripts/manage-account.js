"use strict";

var casper = require('casper').create({
        waitTimeout: 120000,
        pageSettings: {
            userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36'/*,
            loadImages: false,
            loadPlugins: false*/
        }
    }),
    account,
    action,
    actions,
    dropboxUrl;

if ( ! casper.cli.has(6) || casper.cli.has(7)) {
    console.log('Usage: manage-account.js <action> <dropboxUrl> <account_id> <accountFirstName> <accountLastName> <accountEmail> <accountPassword>');
    casper.exit(1);
}

action = casper.cli.get(0);
dropboxUrl = casper.cli.get(1);

if (action !== 'link' && action !== 'create') {
    console.log('The action must be either "link" or "create".');
    casper.exit(1);
}

// Converting to string is essential for "numbers-only" passwords, otherwise Dropbox password field filling bugs.
account = {
    firstName: String(casper.cli.get(3)),
    lastName: String(casper.cli.get(4)),
    password: String(casper.cli.get(6)),
    email: String(casper.cli.get(5).replace(/%s/, casper.cli.get(2)))
};

casper.options.onWaitTimeout = function () {
    this.waitUntilVisible(
        '.error-message',
        function () {
            this.log(this.evaluate(function () { return jQuery('.error-message').text(); }), 'error');
            safeExit(this, 1);
        },
        function () {
            safeExit(this, 1);
        }
    );
};

actions = {
    create: function () {
        var form = 'form[action="/ajax_register"] ',
            formField = form +'input',
            formButton = form +'button.login-button:not([disabled])';

        this.waitForSelector(formButton, function () {
            this.sendKeys(formField +'[name="fname"]', account.firstName);
            this.sendKeys(formField +'[name="lname"]', account.lastName);
            this.sendKeys(formField +'[name="email"]', account.email);
            this.sendKeys(formField +'[name="password"]', account.password);

            var termsAndConditionsIsChecked = this.evaluate(function (formField) {
                return jQuery(formField +'[name="tos_agree"]:checked').length === 1;
            }, formField);

            if ( ! termsAndConditionsIsChecked) {
                this.click(formField +'[name="tos_agree"]');
            }

            this.click(formButton);

            this.wait(5000, function () {
                this.waitForUrl('https://www.dropbox.com/gs', function () {
                    this.capture('screenshots/4_after_page_load.png');
                    var selector = '//*[@id="header-account-menu"]/div/ul/div[1]/span',
                        text = account.email;

                    this.waitUntilVisible(
                        {
                            type: 'xpath',
                            path: selector + '[contains(., "' + text + '")]'
                        },
                        function () {
                            this.log('Account created successfully !', 'info');
                            safeExit(this, 0);
                        }
                    );
                });
            });
        });
    },
    link: function () {
        var form = 'form[action="/cli_link_nonce"] ',
            formField = form +'input',
            formButton = form +'button.login-button:not([disabled="True"])';

        this.waitForSelector(formButton, function () {
            this.sendKeys(formField +'[name="login_email"]', account.email);
            this.sendKeys(formField +'[name="login_password"]', account.password);

            var rememberMeIsChecked = this.evaluate(function (formField) {
                return jQuery(formField +'[name="remember_me"]:checked').length === 1;
            }, formField);

            this.log('Remember me is checked : '+ this.evaluate(function (formField) {
                return jQuery(formField +'[name="remember_me"]:checked').length === 1;
            }, formField), 'debug');

            if (rememberMeIsChecked) {
                this.click(formField +'[name="remember_me"]');
            }

            this.log('Remember me is checked : '+ this.evaluate(function (formField) {
                return jQuery(formField +'[name="remember_me"]:checked').length === 1;
            }, formField), 'debug');

            this.capture('screenshots/1_before_click.png');
            this.click(formButton);
            this.capture('screenshots/2_after_click.png');

            this.waitUntilVisible('.login-loading-indicator', function () {
                this.capture('screenshots/3_loading_visible.png');
                this.waitWhileVisible('.login-loading-indicator', function () {
                    this.capture('screenshots/4_loading_hidden.png');
                    var selector = '//*[@id="page-content"]/div/div[2]/p[1]',
                        text = 'Your computer was successfully linked to your account';

                    this.capture('screenshots/5_before_confirm_visible.png');
                    this.waitUntilVisible(
                        {
                            type: 'xpath',
                            path: selector + '[contains(., "' + text + '")]'
                        },
                        function () {
                            this.capture('screenshots/6_after_confirm_visible.png');
                            this.log('Account was linked successfully !', 'info');
                            safeExit(this, 0);
                        }
                    );
                });
            });
        });
    }
};

casper.start(dropboxUrl);
casper.then(actions[action]);
casper.run();

function safeExit(casper, code)
{
    if (code > 0) {
        casper.capture('screenshots/error_exit_code_' + code + '_timestamp_' + new Date().getTime() + '.png');
    }

    setTimeout(function () {
        casper.exit(code);
    }, 0);
}
