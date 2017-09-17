require 'nokogiri'

class InstructionNotSupported < RuntimeError
end

class ServicePayloadManipulator

	def initialize
		@instructions = {}
	end

	def manipulate_body(body)
		body_to_return = body
	
		fake = Nokogiri::XML(body, nil, Encoding::UTF_8.to_s)
		@instructions.each_key do |element|
			fake_instruction = @instructions[element]
			namespace = fake_instruction[:namespace]

			service_content = fake.xpath("//ns:#{element}", 'ns' => namespace)
			unless service_content.empty?
				if fake_instruction.key?(:values)
					replace_values(fake, namespace, fake_instruction[:values])
				end
				if fake_instruction.key?(:remove)
					remove_elements(fake, namespace, fake_instruction[:remove])
				end
				if fake_instruction.key?(:empty)
					empty_elements(fake, namespace, fake_instruction[:empty])
				end
				if fake_instruction.key?(:add)
					add_elements(fake, namespace, fake_instruction[:add])
				end
				body_to_return = fake.to_xml(:encoding => Encoding::UTF_8.to_s)
			end
		end
		
		body_to_return
	end
	
	def clear_instructions
		@instructions = {}
	end
	
	def method_missing(method, *args, &block)
		if (method.to_s.start_with?("modify_"))
			service_name = method.to_s.scan(/_(.*)/).first.first
			replacement_instructions = args.first
			
			check_instructions(replacement_instructions)
			@instructions[service_name] = replacement_instructions
		else
			raise NoMethodError.new(method, args)
		end
	end

	private
	
	def check_instructions(instructions)
		instructions.each_key do |key|
			raise InstructionNotSupported.new unless [:namespace, :values, :remove, :empty, :add].include?(key)
		end
	end
	
	def replace_values(fake, namespace, values_to_be_replaced)
		values_to_be_replaced.each_key do |value_item_to_be_replaced|
			item = fake.xpath("//#{value_item_to_be_replaced}", 'ns' => namespace)
			unless item.empty?
				item.children.first.content = values_to_be_replaced[value_item_to_be_replaced]
			end
		end
	end
	
	def remove_elements(fake, namespace, elements_to_be_removed)
		elements_to_be_removed.each do |element_to_be_removed|
			item = fake.xpath("//#{element_to_be_removed}", 'ns' => namespace)
			unless item.empty?
				item.remove
			end
		end
	end
	
	def empty_elements(fake, namespace, elements_to_be_emptied)
		elements_to_be_emptied.each do |element_to_be_emptied|
			item = fake.xpath("//#{element_to_be_emptied}", 'ns' => namespace)
			unless item.empty?
				item.children.remove
			end
		end
	end
	
	def add_elements(fake, namespace, elements_to_be_added)
		elements_to_be_added.each do |element_to_be_added|
			item = fake.xpath("//#{element_to_be_added[:node]}", 'ns' => namespace)
			unless item.empty?
				if item.children.empty?
					# note to future self: item behaves like an array
					item.first.add_child element_to_be_added[:content]
				else
					item.children.after(element_to_be_added[:content])
				end
			end
		end
	end
end
