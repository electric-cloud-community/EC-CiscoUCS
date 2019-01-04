@files = (
 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="UCSCreateConfigForm"]/value'  , 'forms/UCSCreateConfigForm.xml'],
 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="UCSEditConfigForm"]/value'  , 'forms/UCSEditConfigForm.xml'],
 
 ['//property[propertyName="response_matchers"]/value', 'matchers/responseMatchers.pl'],

 ['//procedure[procedureName="SendUCSRequest"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'forms/SendUCSRequestForm.xml'],
 
 ['//procedure[procedureName="SendUCSRequest"]/step[stepName="RunUCSRequest"]/command' , 'server/sendUCSRequest.pl'],

 ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command' , 'conf/createcfg.pl'],
 ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateAndAttachCredential"]/command' , 'conf/createAndAttachCredential.pl'],
 ['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command' , 'conf/deletecfg.pl'],

 ['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'],
);
