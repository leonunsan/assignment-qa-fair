require 'selenium-webdriver'
require 'rspec'

describe "FAIR" do

	before(:each) do
	#open Broser
	@driver = Selenium::WebDriver.for :chrome
	#Base URL
	@base_url = "http://credit-test.herokuapp.com/"
	#Maximize broser window
	@driver.manage.window.maximize
	#timeout in seconds
	@driver.manage.timeouts.implicit_wait = 60
	#wait timeout
	@wait = Selenium::WebDriver::Wait.new(:timeout => 30)
	end
	
	context "Line Of Credit Test Fair Page" do
		it "Scenario 1 - Draw value and check results" do
		
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")
							
			
			#They draws $500 on day one
			transaction "Draw","500","1"
			
			#remaining credit limit is $500 and their balance is $500
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $500.00 of $1,000.00")
			
			#They should owe $500 * 0.35 / 365 * 30 = 14.38$ worth of interest on day 30. Total payoff amount would be $514.38
			expect(@driver.find_element(:xpath, '/html/body/p[5]').text).to eq("Interest at 30 days: $14.38")
			expect(@driver.find_element(:xpath, '/html/body/p[6]').text).to eq("Total Payoff at 30 days: $514.38")
									
		end
		
		it "Scenario 2 - Draw value, do payment and draw after that, then check values" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")			
			
			#They draws $500 on day one
			transaction "Draw","500","1"			
			
			#remaining credit limit is $500 and their balance is $500
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $500.00 of $1,000.00")			
			
			#They pay back $200 on day 15
			transaction "Payment","200","15"
			
			#They pay back $100 on day 25
			transaction "Draw","100","25"
			
			#Their total owed interest on day 30 should be 500 * 0.35 / 365 * 15 + 300 * 0.35 / 365 * 10 + 400 * 0.35 / 365 * 5 which is 11.99. Total payment should be $411.99.
			expect(@driver.find_element(:xpath, '/html/body/p[5]').text).to eq("Interest at 30 days: $11.99")
			expect(@driver.find_element(:xpath, '/html/body/p[6]').text).to eq("Total Payoff at 30 days: $411.99")
			
		end
		
		it "Scenario 3 - Value lower than 0 for APR on new line of credit creation" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and -1% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "-1"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Apr must be greater than or equal to 0.0")
		end
		
		it "Scenario 4 - Value lower than 0 for Credit limit on new line of credit creation" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for -$1 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "-2"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Credit limit must be greater than or equal to 0.0")			
		end
		
		it "Scenario 5 - Value bigger than credit limit on the draw action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try draw a valur greater than credit limit
			transaction "Draw","1001","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount cannot exceed the credit limit")			
		end
		
		it "Scenario 6 - Value lower than 0 on the draw action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try draw a value loweer than 0
			transaction "Draw","-1","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount must be greater than 0")			
		end
		
		it "Scenario 7 - Value 0 on the draw action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try draw a value 0 credit limit
			transaction "Draw","0","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount must be greater than 0")			
		end
		
		it "Scenario 8 - Value bigger than what is owed on the payment action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try payment with a value greater than what is owed
			transaction "Payment","100","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount cannot exceed what is owed")			
		end
		
		it "Scenario 9 - Value lower than 0 on the payment action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try payment with a value lower than 0
			transaction "Payment","-1","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount must be greater than 0")			
		end
		
		it "Scenario 10 - Value 0 on the payment action" do
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and 35% APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click
			
			#Validate results on the page
			expect(@driver.find_element(:id => "notice").text).to eq("Line of credit was successfully created.")
			expect(@driver.find_element(:xpath, '/html/body/p[2]').text).to eq("Apr: 35.000%")
			expect(@driver.find_element(:xpath, '/html/body/p[3]').text).to eq("Credit Available: $0.00 of $1,000.00")	

			#Try payment with a value 0
			transaction "Payment","0","1"
						
			#Validate message error
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this transaction from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Amount must be greater than 0")			
		end
		
		it "Scenario 11 - Blank value on the APR on line of credit creation" do		
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and blank APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys ""
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:xpath,'//*[@id="error_explanation"]/h2').text).to eq("2 errors prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li[1]').text).to eq("Apr can't be blank")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li[2]').text).to eq("Apr is not a number")									
		end
		
		it "Scenario 12 - Blank value on the Credit Limit on line of credit creation" do		
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and blank APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys ""
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:xpath,'//*[@id="error_explanation"]/h2').text).to eq("2 errors prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li[1]').text).to eq("Credit limit can't be blank")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li[2]').text).to eq("Credit limit is not a number")
			
		end
		
		it "Scenario 13 - Not number value on the APR on line of credit creation" do		
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and not a number on APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "a"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "1000"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:xpath,'//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Apr is not a number")									
		end
		
		it "Scenario 14 - Not number value on the Credit Limit on line of credit creation" do		
			@driver.get(@base_url + "/")
			
			#Someone creates a line of credit for $1000 and not a number on  APR.
			@driver.find_element(:xpath, '//a[text()="New Line of credit"]').click
			@driver.find_element(:id, 'line_of_credit_apr').send_keys "35"
			@driver.find_element(:id, 'line_of_credit_credit_limit').send_keys "a"
			@driver.find_element(:xpath, '//input[@value="Create Line of credit"]').click	
			
			#Validate results on the page
			expect(@driver.find_element(:xpath,'//*[@id="error_explanation"]/h2').text).to eq("1 error prohibited this line_of_credit from being saved:")
			expect(@driver.find_element(:xpath, '//*[@id="error_explanation"]/ul/li').text).to eq("Credit limit is not a number")
			
		end
	end
end


def transaction (t_type, t_value, t_day)
	@driver.find_element(:id, 'transaction_type').click
	@driver.find_element(:id, 'transaction_type').find_elements( :tag_name => "option" ).find do |option|
		option.text == t_type
		end.click
		
	@driver.find_element(:id, 'transaction_amount').clear	
	@driver.find_element(:id, 'transaction_amount').send_keys t_value	
	
	@driver.find_element(:id, 'transaction_applied_at').click
	@driver.find_element(:id, 'transaction_applied_at').find_elements( :tag_name => "option" ).find do |option|
		option.text == t_day
		end.click
	
	@driver.find_element(:xpath, '//input[@value="Save Transaction"]').click
	sleep 1
end