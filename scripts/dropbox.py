from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.expected_conditions import staleness_of
from bs4 import BeautifulSoup
import time, sys, urllib

def wait_for_page_load(browser, timeout=30):
    old_page = browser.find_element_by_tag_name('html')
    WebDriverWait(browser, timeout).until(staleness_of(old_page))

if sys.argv[1] == 'link':
    from pyvirtualdisplay import Display
    display = Display(visible=0, size=(1920, 1080))
    display.start()

options = webdriver.ChromeOptions()
options.add_argument('--proxy-server=socks5://127.0.0.1:9050')
browser = webdriver.Chrome(chrome_options=options)

browser.set_window_size(1920, 1080)
page_timeout = int(sys.argv[7])
browser.set_script_timeout(page_timeout)
browser.set_page_load_timeout(page_timeout)

while True:
    try:
        browser.get(sys.argv[2])
        break
    except TimeoutException:
        print('Browser get request timed out. Retrying...')

if sys.argv[1] == 'create':
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    fname = WebDriverWait(browser, page_timeout).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] input[name="fname"]'))
    )
    fname.send_keys(sys.argv[3])

    lname = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] input[name="lname"]'))
    )
    lname.send_keys(sys.argv[4])


    email = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] input[name="email'))
    )
    email.send_keys(sys.argv[5])

    password = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] input[name="password"]'))
    )
    password.send_keys(sys.argv[6])

    tos_agree = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] input[name="tos_agree"]'))
    )
    tos_agree.click()

    login_button = WebDriverWait(browser, 10).until(
        EC.element_to_be_clickable((By.CSS_SELECTOR, 'form[action="/ajax_register"] button.login-button'))
    )
    time.sleep(5)

    captcha = browser.find_element_by_css_selector('form[action="/ajax_register"] div.recaptcha_v2_challenge')
    captcha_iframes = captcha.find_elements_by_tag_name('iframe')
    while True:
        if len(captcha_iframes) == 1:
            captcha_iframe = WebDriverWait(browser, 10).until(
                EC.visibility_of_element_located((By.TAG_NAME, 'iframe'))
            )
            browser.switch_to.frame(captcha_iframe)
            captcha_checkbox = WebDriverWait(browser, page_timeout).until(
                EC.visibility_of_element_located((By.ID, 'recaptcha-anchor'))
            )
            while True:
                print('Waiting for captcha input.')
                if captcha_checkbox.get_attribute('aria-checked') == 'true':
                    print('Captcha filled out successfully.')
                    break
                time.sleep(3)
        browser.switch_to.default_content()
        login_button.click()
        try:
            wait_for_page_load(browser, 10)
            if browser.current_url == 'https://www.dropbox.com/install-linux':
                break
        except TimeoutException:
            new_captcha_iframes = captcha.find_elements_by_tag_name('iframe')
            if len(captcha_iframes) == 0 and len(new_captcha_iframes) > 0:
                captcha_iframes = new_captcha_iframes
            else:
                break
    browser.switch_to.default_content()
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
elif sys.argv[1] == 'link':
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    login_button = WebDriverWait(browser, page_timeout).until(
        EC.element_to_be_clickable((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] button.login-button'))
    )
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    login_email = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] input[name="login_email"]'))
    )
    login_email.send_keys(sys.argv[5])
    
    login_password = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] input[name="login_password"]'))
    )
    login_password.send_keys(sys.argv[6])

    remember_me = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] input[name="remember_me"]'))
    )

    if not remember_me.is_selected():
        remember_me.click()

    WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] button.login-button:not([disabled="True"])'))
    )
    login_button.click();
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    print('The account was hopefully linked successfully.')
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')

    while True:
        try:
            browser.get('https://www.dropbox.com/account#profile')
            break
        except TimeoutException:
            print('Browser get request timed out. Retrying...')
    verify_button = WebDriverWait(browser, page_timeout).until(
        EC.visibility_of_element_located((By.XPATH, '//button[contains(text(), \'Verify email\')]'))
    )
    verify_button.click()
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    send_button = WebDriverWait(browser, page_timeout).until(
        EC.visibility_of_element_located((By.XPATH, '//button[contains(text(), \'Send email\')]'))
    )
    send_button.click()
    time.sleep(5)
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
    print('The account was verified successfully.')

browser.quit()
if sys.argv[1] == 'link':
    display.stop()
