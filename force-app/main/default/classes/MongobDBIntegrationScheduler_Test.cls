@isTest
public class MongobDBIntegrationScheduler_Test 
{
    @TestSetup
    public static void TestSetup()
    {
        MongoDB_Integration_Meta__c usersMeta = new MongoDB_Integration_Meta__c();
        MongoDB_Integration_Meta__c reviewsMeta = new MongoDB_Integration_Meta__c();
        MongoDB_Integration_Meta__c venuesMeta = new MongoDB_Integration_Meta__c();
        MongoDB_Integration_Meta__c eventsMeta = new MongoDB_Integration_Meta__c();
        usersMeta.Name = 'Users';
        usersMeta.offset__c = 0;
        usersMeta.total_records__c = 1110;
        usersMeta.Chunk_Size__c = 10;
        insert usersMeta;
        
        reviewsMeta.Name = 'Reviews';
        reviewsMeta.offset__c = 0;
        reviewsMeta.total_records__c = 1110;
        reviewsMeta.Chunk_Size__c = 10;
        insert reviewsMeta;
        
        venuesMeta.name = 'Venues';
        venuesMeta.offset__c = 0;
        venuesMeta.total_records__c = 1110;
        venuesMeta.Chunk_Size__c = 10;
        insert venuesMeta;
        
        eventsMeta.name = 'Events';
        eventsMeta.offset__c = 0;
        eventsMeta.total_records__c = 1110;
        eventsMeta.Chunk_Size__c = 10;
        insert eventsMeta;
        
        
    }
    @isTest
    public static void testFetchUsersFunction()
    {
        Test.setMock(HttpCalloutMock.Class, new MockTestResponse()); 
        Test.startTest();
        MongobDBIntegrationScheduler.fetchAllUsersFromAWS();
        Test.StopTest();
        
    }
    @isTest
    public static void testFetchVenuesFunction()
    {
        Test.setMock(HttpCalloutMock.Class, new MockTestResponse()); 
        Test.startTest();
        MongobDBIntegrationScheduler.fetchAllVenuesFromAWS();
        Test.StopTest();
        
    }
    @isTest
    public static void testFetchReviewsFunction()
    {
        Test.setMock(HttpCalloutMock.Class, new MockTestResponse()); 
        Test.startTest();
        MongobDBIntegrationScheduler.fetchAllReviewsFromAWS();
        Test.StopTest();
        
    }
    @isTest
    public static void testFetchEventFunction()
    {
        Test.setMock(HttpCalloutMock.Class, new MockTestResponse()); 
        Test.startTest();
        MongobDBIntegrationScheduler.fetchAllEventsFromAWS();
        Test.StopTest();
        
    }
}