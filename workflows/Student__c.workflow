<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Email_Confirmation_for_student_s_record_creation</fullName>
        <ccEmails>omkar.kumar857@gmail.com</ccEmails>
        <description>Email Confirmation for student&apos;s record creation</description>
        <protected>false</protected>
        <recipients>
            <field>EmailID__c</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/EmailConfirmationStudent</template>
    </alerts>
    <rules>
        <fullName>Email confirmation</fullName>
        <actions>
            <name>Email_Confirmation_for_student_s_record_creation</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Student__c.EmailID__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
