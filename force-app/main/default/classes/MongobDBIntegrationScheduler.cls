global class MongobDBIntegrationScheduler implements Schedulable , Database.AllowsCallouts
{
    global void execute(SchedulableContext SC) 
    {
        fetchAllUsersFromAWS();
        fetchAllReviewsFromAWS();
        fetchAllVenuesFromAWS();
        fetchAllEventsFromAWS();
    }
    @future(callout=true)
    public static void  fetchAllEventsFromAWS()
    {
        List<MongoDB_Integration_Meta__c> meta = [Select Id, name, offset__c, total_records__c,Chunk_Size__c
                                                  FROM MongoDB_Integration_Meta__c
                                                  WHERE Name = 'Events'];
        if(meta != null && meta.size() > 0 && meta[0].offset__c < meta[0].total_records__c)
        {
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();                
            request.setMethod('GET');                
            if(Test.isRunningTest()){
                request.setEndpoint('http://test.com/test/fetchEvents');
            }
            else
            {
                request.setEndPoint(System.Label.MongoDbGetAllEvents+'?offset='+meta[0].offset__c);
            }  
            response = http.send(request);
            List<Event__c> eventsToInsert = new List<Event__c>();
            if(response.getStatusCode() == 200)
            {
                String jsonString = response.getBody();
                jsonString = jsonString.replace('_id', 'x_id');
                List<Events.EventDetails> events = (List<Events.EventDetails>) System.JSON.deserialize(jsonString, List<Events.EventDetails>.class);
                List<String> mongoDbIds = new List<String>();
                List<Contact> contacts = new List<Contact>();
                Map<String,Id> mongoDbToContactId = new Map<String,Id>(); 
                for(Events.EventDetails event : events)
                {
                    if(event.managers != null && event.managers.size() > 0)
                    {
                        mongoDbIds.add(event.managers[0]);   
                    }
                }
                contacts = [SELECT Id, MongoDb_Id__c 
                            FROM Contact 
                            WHERE MongoDb_Id__c = :mongoDbIds];
                for(Contact con : contacts)
                {
                    mongoDbToContactId.put(con.MongoDb_Id__c, con.Id); 
                }
                for(Events.EventDetails event : events)
                {
                    Event__c eve = new Event__c();
                    eve.MongoDb_Id__c = event.x_id;
                    eve.Description__c = event.description;
                    eve.End_Date__c = Date.valueOf(event.endDate);
                    eve.name = event.name;
                    eve.Participants_Goal__c = Integer.valueOf(event.participantsGoal);
                    eve.reviewsGoal__c = Integer.valueOf(event.reviewsGoal);
                    eve.Start_Date__c = Date.valueOf(event.startDate);
                    eve.Review_Amount__c = Integer.valueOf(event.reviewsAmount);
                    eve.address__c = event.address;
                    eve.Poster__c = event.poster;
                    if(event.managers != null && event.managers.size() > 0)
                    {
                        eve.Manager__c =  mongoDbToContactId.containsKey(event.managers[0]) ? mongoDbToContactId.get(event.managers[0]) : null;
                    }
                    if(event.location != null && event.location.coordinates != null && event.location.coordinates.size() > 0)
                    {
                        eve.Location__longitude__s = event.location.coordinates[0];
                        eve.Location__latitude__s  = event.location.coordinates[1];
                        eve.Location__latitude__s = eve.Location__latitude__s.setScale(2);
                        eve.Location__longitude__s = eve.Location__longitude__s.setScale(2);
                    }
                    eventsToInsert.add(eve);
                }
                Database.UpsertResult[] srList = Database.upsert(eventsToInsert, false);
                // Iterate through each returned result
                for (Database.UpsertResult sr : srList) 
                {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted Event ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Event fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                system.debug(eventsToInsert.size());
                meta[0].offset__c += meta[0].Chunk_Size__c;
                update meta[0];
            }
        }
    }

    @future(callout=true)
    public static void  fetchAllUsersFromAWS()
    {
        List<MongoDB_Integration_Meta__c> meta = [Select Id, name, offset__c, total_records__c,Chunk_Size__c
                                                  FROM MongoDB_Integration_Meta__c
                                                  WHERE Name = 'Users'];
        if(meta != null && meta.size() > 0 && meta[0].offset__c < meta[0].total_records__c)
        {
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();                
            request.setMethod('GET');                
            if(Test.isRunningTest()){
                request.setEndpoint('http://test.com/test/fetchUsers');
            }
            else
            {
                request.setEndPoint(System.Label.MongoDbGetAllUsers+'?offset='+meta[0].offset__c);
            }  
            response = http.send(request);
          	List<Contact> usersToInsert = new List<Contact>();
            if(response.getStatusCode() == 200)
            {
                String jsonString = response.getBody();
                jsonString = jsonString.replace('_id', 'x_id');
                List<Reviews.UserDetails> users = (List<Reviews.UserDetails>) System.JSON.deserialize(jsonString, List<Reviews.UserDetails>.class);
                for(Reviews.UserDetails user : users)
                {
                    Contact con = new Contact();
                    con.MongoDb_Id__c = user.x_id;
                    con.FirstName = user.FirstName;
                    con.LastName = user.LastName;
                    con.Description = user.Description;
                    con.Phone = user.Phone;
                    con.Created_Updated_from_Scheduler__c = true;
                    con.Gender_Identity__c = user.gender;
                    con.Disability_Type__c = String.join(user.disabilities, ';');
                    con.Email = user.email;
                    usersToInsert.add(con);
                }
                Database.UpsertResult[] srList = Database.upsert(usersToInsert, false);
                // Iterate through each returned result
                for (Database.UpsertResult sr : srList) 
                {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted User ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                system.debug(usersToInsert.size());
                meta[0].offset__c += meta[0].Chunk_Size__c;
                update meta[0];
            }
        }
    }
    @future(callout=true)
    public static void fetchAllVenuesFromAWS()
    {
        List<MongoDB_Integration_Meta__c> meta = [Select Id, name, offset__c, total_records__c,Chunk_Size__c
                                                  FROM MongoDB_Integration_Meta__c WHERE Name = 'Venues'];
        if(meta != null && meta.size() > 0 && meta[0].offset__c < meta[0].total_records__c)
        {
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();                
            request.setMethod('GET');                
            if(Test.isRunningTest()){
                request.setEndpoint('http://test.com/test/fetchVenues');
            }
            else
            {
                request.setEndPoint(System.Label.MongoDbGetAllVenues+'/default/getAllVenues?offset='+meta[0].offset__c);
            }  
            response = http.send(request);
          	List<Venue__c> venuesToInsert = new List<Venue__c>();
            if(response.getStatusCode() == 200)
            {
                String jsonString = response.getBody();
                jsonString = jsonString.replace('_id', 'x_id');
                jsonString = jsonString.replace('__v', 'x_v');
                jsonString = jsonString.replace('_bathroomScore', 'x_bathroomScore');
                jsonString = jsonString.replace('_bathroomReviews', 'x_bathroomReviews');
                jsonString = jsonString.replace('_entryScore', 'x_entryScore');
                jsonString = jsonString.replace('_entryReviews', 'x_entryReviews');
                jsonString = jsonString.replace('_isScoreConverted', 'x_isScoreConverted');
                List<Venues.VenueDetails> venues = (List<Venues.VenueDetails>) System.JSON.deserialize(jsonString, List<Venues.VenueDetails>.class);
                for(Venues.VenueDetails venue : venues)
                {
                    Venue__c v = new Venue__c();
                    v.Address__c = venue.address;
                    v.allowsGuideDog__c = venue.allowsGuideDog.yes == 1.0;
                    v.BathroomReviews__c = venue.x_bathroomReviews;
                    v.BathroomScore__c = venue.x_bathroomScore;
                    v.EntranceScore__c = venue.entranceScore;
                    v.entryReviews__c = venue.x_entryReviews;
                    v.EntryScore__c = venue.x_entryScore;
                    v.hasAccessibleElevator__c = venue.hasAccessibleElevator.yes == 1.0;
                    v.hasAccessibleTableHeight__c = venue.hasAccessibleTableHeight.yes == 1.0;
                    v.hasInteriorRamp__c = venue.hasInteriorRamp.yes == 1.0;
                    v.hasLargeStall__c = venue.hasLargeStall.yes == 1.0;
                    v.hasLoweredSinks__c = venue.hasLoweredSinks.yes == 1.0;
                    v.hasParking__c = venue.hasParking.yes == 1.0;
                    v.hasPermanentRamp__c = venue.hasPermanentRamp.yes == 1.0;
                    v.hasSecondEntry__c = venue.hasSecondEntry.yes == 1.0;
                    v.hasSupportAroundToilet__c = venue.hasSupportAroundToilet.yes == 1.0;
                    v.hasSwingOutDoor__c = venue.hasSwingOutDoor.yes == 1.0;
                    v.hasWellLit__c = venue.hasWellLit.yes == 1.0;
                    v.hasWideEntrance__c = venue.hasWideEntrance.yes == 1.0;
                    v.interiorScore__c = venue.interiorScore;
                    v.isQuiet__c = venue.isQuiet.yes == 1.0;
                    v.IsScoreConverted__c = venue.x_isScoreConverted;
                    v.IsSpacious__c = venue.IsSpacious.yes == 1.0;
                    if(venue.location != null && venue.location.coordinates != null && venue.location.coordinates.size() > 0)
                    {
                        v.Location_Coordinates__longitude__s = venue.location.coordinates[0];
                        v.Location_Coordinates__latitude__s  = venue.location.coordinates[1];
                        v.Location_Coordinates__latitude__s = v.Location_Coordinates__latitude__s.setScale(2);
                        v.Location_Coordinates__longitude__s = v.Location_Coordinates__longitude__s.setScale(2);
                    }
                    v.mapMarkerScore__c = venue.mapMarkerScore;
                    v.Mongo_Db_Id__c = venue.x_Id;
                    v.Name__c = venue.Name;
                    v.Types__c = string.join(venue.types,';');
                    venuesToInsert.add(v);
                }
                Database.UpsertResult[] srList = Database.upsert(venuesToInsert, false);
                // Iterate through each returned result
                for (Database.UpsertResult sr : srList) 
                {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted Venue ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                system.debug(venuesToInsert.size());
                meta[0].offset__c += meta[0].Chunk_Size__c;
                update meta[0];
            }
        }
    }
    
    @future(callout=true)
    public static void fetchAllReviewsFromAWS()
    {
        List<MongoDB_Integration_Meta__c> meta = [Select Id, name, offset__c, total_records__c,Chunk_Size__c
                                                  FROM MongoDB_Integration_Meta__c WHERE Name = 'Reviews'];
        if(meta != null && meta.size() > 0 && meta[0].offset__c < meta[0].total_records__c)
        {
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();                
            request.setMethod('GET');                
            if(Test.isRunningTest()){
                request.setEndpoint('http://test.com/test/fetchReviews');
            }
            else
            {
                request.setEndPoint(System.Label.MongoDbGetAllReviews+'/default/?offset='+meta[0].offset__c);
            }
            //  request.setHeader('API key' , '470YcM9Ydz54sfVqajfqH8cfUIyddhiS1ua05BqS');
            //  System.debug('IN Sync Customers 7 '+qbcList[0].Access_token__c);
            // request.setHeader('Content-Type' , 'application/json;charset=UTF-8');
            response = http.send(request);
            Map<String, Reviews.ReviewDetail> emailToReviewDetailMap = new Map<String, Reviews.ReviewDetail> ();
            if(response.getStatusCode() == 200)
            {
                String jsonString = response.getBody();
                jsonString = jsonString.replace('_id', 'x_id');
                jsonString = jsonString.replace('_entryScore', 'x_entryScore');
                jsonString = jsonString.replace('_bathroomScore', 'x_bathroomScore');
                jsonString = jsonString.replace('_isScoreConverted', 'x_isScoreConverted');
                System.debug(response.getStatusCode());
                List<Reviews.ReviewDetail> reviews = (List<Reviews.ReviewDetail>) System.JSON.deserialize(jsonString, List<Reviews.ReviewDetail>.class);
                for(Reviews.ReviewDetail re : reviews)
                {
                    if(re.userDetails.size() > 0)
                    {
                        emailToReviewDetailMap.put(re.userDetails[0].email,re);
                    }
                }
                Map<String,Contact> emailToContactMap = new Map<String,Contact>();
                List<Contact> contactList = new List<Contact>();
                contactList = [SELECT Id, IsDeleted, MasterRecordId, AccountId, LastName, FirstName, Salutation, Name, OtherStreet, OtherCity, OtherState, OtherPostalCode, 
                               OtherCountry, OtherLatitude, OtherLongitude, OtherGeocodeAccuracy, OtherAddress, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                               MailingCountry, MailingLatitude, MailingLongitude, MailingGeocodeAccuracy, MailingAddress, Phone, Fax, MobilePhone, HomePhone, OtherPhone, AssistantPhone,
                               ReportsToId, Email, Title, Department, AssistantName, LeadSource, Birthdate, Description, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                               SystemModstamp, LastActivityDate, LastCURequestDate, LastCUUpdateDate, LastViewedDate, LastReferencedDate, EmailBouncedReason, EmailBouncedDate, IsEmailBounced,
                               PhotoUrl, Jigsaw, JigsawContactId, IndividualId, Location__c, Member_Rating__c, IP_Address__c, Confirm_Time__c, Status__c, npe01__AlternateEmail__c, Enrolled__c,
                               Notes__c, Standby__c, Referred__c, Availability__c, npe01__HomeEmail__c, npe01__Home_Address__c, npe01__Organization_Type__c, npe01__Other_Address__c, npe01__PreferredPhone__c
                               , Donated__c, Score__c, Age__c, Race__c, Gender_Identity__c, Sexual_Identity__c, Highest_level_of_education__c, Work_status__c, Household_income__c, Disability__c, Disability_Type__c, AXS_Map_Gold_Member__c, Email_Campaigns__c
                               FROM Contact
                               WHERE Email =: emailToReviewDetailMap.keySet()];
                for(Contact con : contactList)
                {
                    emailToContactMap.put(con.Email,con);
                }
                contactList.clear();
                List<Review__c> reviewList = new List<Review__c>();
                Map<String,Boolean> isEmailExistqMap = new Map<String,Boolean>();
                Map<String,Contact> emailToContactRecordId = new Map<String,Contact>();
                for(Reviews.ReviewDetail re : reviews)
                {
                    if(re.userDetails.size() > 0)
                    {
                        if(!isEmailExistqMap.containsKey(re.userDetails[0].email))
                        {
                            Contact con = new Contact();
                            if(emailToContactMap.containsKey(re.userDetails[0].email))
                            {
                                con = emailToContactMap.get(re.userDetails[0].email);
                            }
                            con.MongoDb_Id__c = re.userDetails[0].x_id;
                            con.FirstName = re.userDetails[0].FirstName;
                            con.LastName = re.userDetails[0].LastName;
                            con.Description = re.userDetails[0].Description;
                            con.Phone = re.userDetails[0].Phone;
                            con.Created_Updated_from_Scheduler__c = true;
                            con.Email = re.userDetails[0].email;
                            isEmailExistqMap.put(re.userDetails[0].email,true);
                            emailToContactRecordId.put(re.userDetails[0].email,con);
                            contactList.add(con);
                        }
                    }
                }
                Database.UpsertResult[] srList = Database.upsert(contactList, false);
                
                // Iterate through each returned result
                for (Database.UpsertResult sr : srList) 
                {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted Contact. Contact ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Contact fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                
                for(Reviews.ReviewDetail re : reviews)
                {
                    Review__c review = new Review__c();
                    review.MongoDb_Id__c = re.x_id;
                    review.MongoDb_Id_venue__c = re.venue;
                    review.MongoDb_Id_User__c = re.user;
                    review.allowsGuideDog__c = re.allowsGuideDog != null ? re.allowsGuideDog : false;
                    review.bathroomScore__c = re.x_bathroomScore != null ? re.x_bathroomScore : 0;
                    if(re.userDetails.size() > 0)
                        review.Contact__c = emailToContactRecordId.containsKey(re.userDetails[0].email) ? emailToContactRecordId.get(re.userDetails[0].email).Id : null;
                    review.entryScore__c = re.x_entryScore!= null ? re.x_entryScore : 0;
                    review.hasLargeStall__c = re.hasLargeStall != null ? re.hasLargeStall : false;
                    review.hasLoweredSinks__c = re.hasLoweredSinks != null ? re.hasLoweredSinks : false;
                    review.hasParking__c = re.hasParking != null ? re.hasParking : false;
                    review.hasPermanentRamp__c = re.hasPermanentRamp != null ? re.hasPermanentRamp : false;
                    review.hasRamp__c = re.hasRamp != null ? re.hasRamp : false;
                    review.hasSecondEntry__c = re.hasSecondEntry != null ? re.hasSecondEntry : false;
                    review.hasSupportAroundToilet__c = re.hasSupportAroundToilet != null ? re.hasSupportAroundToilet : false;      
                    review.hasSwingOutDoor__c = re.hasSwingOutDoor != null ? re.hasSwingOutDoor : false;
                    review.hasWellLit__c = re.hasWellLit != null ? re.hasWellLit : false;
                    review.isBanned__c = re.isBanned != null ? re.isBanned : false;
                    review.comments__c = re.comments;
                    review.isQuiet__c = re.isQuiet != null ? re.isQuiet : false;
                    review.isSpacious__c = re.isSpacious != null ? re.isSpacious : false;
                    reviewList.add(review);
                }
                srList = Database.upsert(reviewList, false);
                // Iterate through each returned result
                for (Database.UpsertResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted Review. Review ID: ' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('The following error has occurred.');                    
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                    }
                }
                system.debug(reviewList.size());
                system.debug(contactList.size());
                meta[0].offset__c += meta[0].Chunk_Size__c;
                update meta[0];
            }
        }
        
    }
}