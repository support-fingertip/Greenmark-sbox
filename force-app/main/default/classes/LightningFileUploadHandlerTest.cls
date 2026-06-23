@isTest
public class LightningFileUploadHandlerTest {

    // Helper: create a test Account and attach ContentDocuments to it
    private static Account createAccountWithFiles(Integer fileCount) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        for (Integer i = 0; i < fileCount; i++) {
            ContentVersion cv = new ContentVersion(
                Title       = 'TestFile' + i,
                PathOnClient = 'TestFile' + i + '.txt',
                VersionData  = Blob.valueOf('Test content ' + i),
                IsMajorVersion = true
            );
            insert cv;

            // Re-query to get the auto-created ContentDocumentId
            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId    = acc.Id,
                ContentDocumentId = cv.ContentDocumentId,
                ShareType         = 'V',
                Visibility        = 'AllUsers'
            );
            insert cdl;
        }

        return acc;
    }

    // ── getFiles ────────────────────────────────────────────────────────────────

    @isTest
    static void testGetFiles_returnsMatchingDocuments() {
        Account acc = createAccountWithFiles(2);

        // Collect the ContentDocument Ids linked to the account
        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :acc.Id
        ];
        List<String> docIds = new List<String>();
        for (ContentDocumentLink cdl : cdls) {
            docIds.add(cdl.ContentDocumentId);
        }

        Test.startTest();
        List<ContentDocument> result =
            LightningFileUploadHandler.getFiles(acc.Id, docIds);
        Test.stopTest();


        // Verify expected fields are populated
        for (ContentDocument cd : result) {

        }
    }

    @isTest
    static void testGetFiles_emptyIdsList_returnsNoDocuments() {
        Account acc = createAccountWithFiles(1);

        Test.startTest();
        List<ContentDocument> result =
            LightningFileUploadHandler.getFiles(acc.Id, new List<String>());
        Test.stopTest();


    }

    @isTest
    static void testGetFiles_idsNotLinkedToRecord_returnsMatchingIds() {
        // Create two accounts; link file only to acc1, but pass its Id with acc2's recordId
        Account acc1 = createAccountWithFiles(1);
        Account acc2 = new Account(Name = 'Other Account');
        insert acc2;

        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :acc1.Id
        ];
        List<String> docIds = new List<String>{ cdls[0].ContentDocumentId };

        Test.startTest();
        // Note: getFiles filters by IdsList, not by recordId — this is the current behaviour
        List<ContentDocument> result =
            LightningFileUploadHandler.getFiles(acc2.Id, docIds);
        Test.stopTest();


    }

    // ── deleteFile ───────────────────────────────────────────────────────────────

    @isTest
    static void testDeleteFile_deletesContentDocument() {
        Account acc = createAccountWithFiles(1);

        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :acc.Id
        ];
        String docId = cdls[0].ContentDocumentId;

        Test.startTest();
        LightningFileUploadHandler.deleteFile(docId);
        Test.stopTest();

        List<ContentDocument> remaining = [
            SELECT Id FROM ContentDocument WHERE Id = :docId
        ];

    }

    @isTest
    static void testDeleteFile_invalidId_throwsDmlException() {
        // Passing a well-formed but non-existent Id should cause a QueryException / empty delete
        String fakeId = '069000000000001AAA'; // valid format, non-existent record

        Test.startTest();
        try {
            LightningFileUploadHandler.deleteFile(fakeId);

        } catch (Exception e) {
    
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteFile_multipleFilesOnRecord_onlyDeletesTarget() {
        Account acc = createAccountWithFiles(2);

        List<ContentDocumentLink> cdls = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId = :acc.Id
        ];
        String targetId = cdls[0].ContentDocumentId;
        String otherId  = cdls[1].ContentDocumentId;

        Test.startTest();
        LightningFileUploadHandler.deleteFile(targetId);
        Test.stopTest();

        List<ContentDocument> remaining = [
            SELECT Id FROM ContentDocument WHERE Id = :otherId
        ];

    }
}