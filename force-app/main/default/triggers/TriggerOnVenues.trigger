trigger TriggerOnVenues on Venue__c (after insert,after Update) 
{
    TriggerOnVenueHandler handler = new TriggerOnVenueHandler(Trigger.new, Trigger.oldMap);
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            handler.afterInsert();
        }
        if(Trigger.IsUpdate)
        {
            handler.afterUpdate();
        }
    }

}