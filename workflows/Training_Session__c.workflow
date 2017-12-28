<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Opt_to_Training_days</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Training_Session__c.Opt_Options__c</field>
            <operation>equals</operation>
            <value>Yes</value>
        </criteriaItems>
        <description>Based on selection of &quot;Opt Option&quot; (Y/N), Number of Training days to be provided [ If Opt Option is Y, then Number of Training Days must be provided ]</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
