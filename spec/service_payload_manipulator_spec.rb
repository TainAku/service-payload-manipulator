require 'rspec'
require 'service_payload_manipulator'

RSpec.describe ServicePayloadManipulator do
	manipulator = ServicePayloadManipulator.new

	describe "setup manipulation instructions" do
		it "throws an exception for unknown method calls" do
			begin
				manipulator.do_not_know
				fail "Call attempt did not raise an exception"
			rescue Exception => e 
				expect(e).to be_instance_of(NoMethodError)
			end
		end
		
		it "throws an exception for unknown instructions" do
			expect {
				manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
					:is_not_supported => []
				})
			}.to raise_error(InstructionNotSupported)
		end
		
	end
	
	describe "#clear_instructions" do
		document = <<-EOF
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
			  <soapenv:Body>
				<ns2:SomeService xmlns:ns2="http://services/">
				  <errorCODE>unchanged</errorCODE>
				</ns2:SomeService>
			  </soapenv:Body>
			</soapenv:Envelope>
		EOF

		it "removes instructions" do
			manipulator.modify_SomeService({
				:namespace => 'http://services/',
				:values => {
					:errorCODE => 'changed'
				}
			})

			manipulator.clear_instructions
			result = manipulator.manipulate_body(document)
			
			expect(Nokogiri::XML(result).xpath("//errorCODE").text).to eql("unchanged")
		end
	end

	describe "#manipulate_body" do
		document = <<-EOF
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
				  <soapenv:Body>
					<ns2:getWSCustomerReputationRiskInfoOutParmsResponse xmlns:ns2="http://services/">
					  <return>
						<errorCODE>ABC4722</errorCODE>
						<errorTEXT>Fake data</errorTEXT>
					  </return>
					</ns2:getWSCustomerReputationRiskInfoOutParmsResponse>
				  </soapenv:Body>
				</soapenv:Envelope>
			EOF

		it "returns the body without changes" do
			expect(ServicePayloadManipulator.new.manipulate_body("<xml/>")).to eql("<xml/>")
		end

		it "modifies concerned service leaves everything else alone" do
			manipulator.modify_NonExisting({
				:namespace => 'http://services/',
				:values => {
					:something => 'changed'
				}
			})

			expect(manipulator.manipulate_body(document)).to eql(document)
		end
		
		it "replaces a value in an element" do
			manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
				:namespace => 'http://services/',
				:values => {
					:errorCODE => 'changed'
				}
			})
			result = manipulator.manipulate_body(document)
			
			expect(Nokogiri::XML(result).xpath("//errorCODE").text).to eql("changed")
		end

		it "empties a value in an element" do
			manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
				:namespace => 'http://services/',
				:values => {
					:errorCODE => ''
				}
			})
			result = manipulator.manipulate_body(document)
			
			expect(Nokogiri::XML(result).xpath("//errorCODE").text).to be_empty
		end
		
		it "removes an existing node" do
			manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
				:namespace => 'http://services/',
				:remove => [ 'return' ]
			})
			result = manipulator.manipulate_body(document)
			
			expect(Nokogiri::XML(result).xpath("//return")).to be_empty
		end
		
		it "empties out an existing node" do
			manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
				:namespace => 'http://services/',
				:empty => [ 'return' ]
			})
			result = manipulator.manipulate_body(document)
			
			expect(Nokogiri::XML(result).xpath("//return")).not_to be_empty
			expect(Nokogiri::XML(result).xpath("//return").children).to be_empty
		end
		
		it "adds a node" do
			manipulator.modify_getWSCustomerReputationRiskInfoOutParmsResponse({
				:namespace => 'http://services/',
				:add => [
					{
						:node => 'return',
						:content => '<to_add><content>something</content></to_add>' 
					}
				]
			})
			result = manipulator.manipulate_body(document)
			expect(Nokogiri::XML(result).xpath("//return/to_add")).not_to be_empty
		end

		it "adds to an empty node" do
			special_doc = <<-EOF
				<?xml version="1.0" encoding="UTF-8"?>
				<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
					<soapenv:Body>
						<ns3:WSCustomerSearchClientsGetResponse xmlns:ns3="http://services/" xmlns:ns2="http://services/">
							<response>
								<outCommonParms>
									<outCommonParmsExt>
										<name>logUID</name>
										<value>eqWS7-170818-113551-39852</value>
									</outCommonParmsExt>
								</outCommonParms>
								<outParms>
									<resultSet></resultSet>
								</outParms>
							</response>
						</ns3:WSCustomerSearchClientsGetResponse>
					</soapenv:Body>
				</soapenv:Envelope>
			EOF

			manipulator.modify_WSCustomerSearchClientsGetResponse({
				:namespace => 'http://services/',
				:add => [
					{
						:node => 'resultSet',
						:content => '<to_add><content>something</content></to_add>' 
					}
				]
			})
			result = manipulator.manipulate_body(special_doc)
			expect(Nokogiri::XML(result).xpath("//resultSet/to_add")).not_to be_empty
		end

	end
end
