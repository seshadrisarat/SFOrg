<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_to_DL_Manager_about_deactivation_and_necessary_details_with_links</fullName>
        <ccEmails>okumar@adobe.com</ccEmails>
        <description>Email to DL/Manager about deactivation and necessary details with links</description>
        <protected>false</protected>
        <recipients>
            <recipient>Project_Manager</recipient>
            <type>role</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/UserDeactivateActionInfoMail</template>
    </alerts>
    <rules>
        <fullName>UserDeactivateAction</fullName>
        <actions>
            <name>Email_to_DL_Manager_about_deactivation_and_necessary_details_with_links</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>User.IsActive</field>
            <operation>equals</operation>
            <value>False</value>
        </criteriaItems>
        <description>Actions after a user is deactivated</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
