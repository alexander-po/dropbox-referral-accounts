from pyvirtualdisplay import Display
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time, sys

display = Display(visible=0, size=(1920, 1080))
display.start()

options = webdriver.ChromeOptions()
options.add_argument('--proxy-server=socks5://127.0.0.1:9050')
browser = webdriver.Chrome(chrome_options=options)

browser.set_window_size(1920, 1080)
browser.set_script_timeout(int(sys.argv[7]))
browser.set_page_load_timeout(int(sys.argv[7]))

browser.get('https://api.ipify.org/?format=json')
time.sleep(5)
print(browser.page_source)

browser.get(sys.argv[2])

if sys.argv[1] == 'create':
    fname = WebDriverWait(browser, 20).until(
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
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/ajax_register"] button.login-button'))
    )
    login_button.click()
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')

    browser.quit()
    display.stop()
elif sys.argv[1] == 'link':
    login_button = WebDriverWait(browser, 20).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'form[action="/cli_link_nonce"] button.login-button'))
    )
    
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

    WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, '.login-loading-indicator'))
    )
    selector = '//*[@id="page-content"]/div/div[2]/p[1]'
    text = 'Your computer was successfully linked to your account';

    time.sleep(.25);
    page_header = WebDriverWait(browser, 10).until(
        EC.visibility_of_element_located((By.CSS_SELECTOR, 'p.page-header-text'))
    )
    if page_header.text.strim() == 'Your computer was successfully linked to your account':
        print('The account was linked successfully!')
    else:
        print('Something went wrong when trying to link the account.')
    browser.save_screenshot('screenshots/dropbox_' + str(time.time()) + '.png')
