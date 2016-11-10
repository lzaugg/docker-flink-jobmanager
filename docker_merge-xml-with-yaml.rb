#!/usr/bin/ruby
require 'rexml/document'                                                                                                                                                            
include REXML                                                                                                                                                                       
                                                                                                                                                                                    
require 'yaml'                                                                                                                                                                      
                                                                                                                                                                                    
if (ARGV.length != 2)                                                                                                                                                               
        puts 'expected exactly 2 params (filenames) to merge properties <xml config file> <yaml config file>; got ' + ARGV.length.to_s                                              
        exit 1                                                                                                                                                                      
end                                                                                                                                                                                 
                                                                                                                                                                                    
yaml_file_path = ARGV[1]                                                                                                                                                            
xml_file_path = ARGV[0]                                                                                                                                                             
                                                                                                                                                                                    
#xmlfile = File.new("/opt/hadoop/etc/hadoop/core-site.xml")                                                                                                                         
xmlfile = File.new(xml_file_path)                                                                                                                                                   
yamlfile = YAML.load_file(yaml_file_path)                                                                                                                                           
                                                                                                                                                                                    
xmldoc = Document.new(xmlfile)                                                                                                                                                      
                                                                                                                                                                                    
configuration_root = xmldoc.elements["configuration"]                                                                                                                               
                                                                                                                                                                                    
if (configuration_root == nil)                                                                                                                                                      
        puts 'could not find configuration root element in file ', xml_file_path                                                                                                    
        exit 1                                                                                                                                                                      
end                                                                                                                                                                                 
                                                                                                                                                                                    
yamlfile.each {                                                                                                                                                                     
        |k,v|
        property_element = configuration_root.add_element("property")                                                                                                               
        name_element = property_element.add_element("name")                                                                                                                         
        name_element.add_text(k)                                                                                                                                                    
        value_element = property_element.add_element("value")                                                                                                                       
        value_element.add_text(v)                                                                                                                                                   
}                                                                                                                                                                                   
                                                                                                                                                                                    
formatter = REXML::Formatters::Pretty.new                                                                                                                                           
formatter.compact = true                                                                                                                                                            
formatter.write(xmldoc, $stdout)