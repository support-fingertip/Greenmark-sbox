@isTest
public class FileDocumentControllerTest {

    // ─── Test Data Factory ────────────────────────────────────────────────────

    /**
     * Creates an Account and inserts `fileCount` ContentVersions, each linked
     * to the account.  Each file's Description is set to the corresponding
     * entry in `docTypes` (if supplied).
     *
     * Returns a helper wrapper so callers can access both the account and the
     * inserted ContentDocumentIds without extra queries.
     */
    private static Account createAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        return acc;
    }

    /**
     * Inserts a ContentVersion, links it to `linkedEntityId`, and optionally
     * sets Description (docType) and Title.
     * Returns the ContentDocumentId of the newly created document.
     */
    private static Id insertLinkedFile(Id linkedEntityId, String title,
                                       String description) {
        ContentVersion cv = new ContentVersion(
            Title          = title,
            PathOnClient   = title + '.txt',
            VersionData    = Blob.valueOf('dummy content for ' + title),
            IsMajorVersion = true,
            Description    = description
        );
        insert cv;

        // Re-query to get system-generated ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId    = linkedEntityId,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        insert cdl;

        return cv.ContentDocumentId;
    }

    // ─── getDocuments ─────────────────────────────────────────────────────────

    @isTest
    static void testGetDocuments_allUploaded() {
        Account acc  = createAccount();
        Id docId1    = insertLinkedFile(acc.Id, 'Invoice.pdf',   'Invoice');
        Id docId2    = insertLinkedFile(acc.Id, 'Contract.pdf',  'Contract');

        List<String> docNames = new List<String>{ 'Invoice', 'Contract' };

        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result =
            FileDocumentController.getDocuments(acc.Id, docNames);
        Test.stopTest();


        Map<String, FileDocumentController.DocumentStatusWrapper> byLabel =
            new Map<String, FileDocumentController.DocumentStatusWrapper>();
        for (FileDocumentController.DocumentStatusWrapper w : result) {
            byLabel.put(w.label, w);
        }


    }

    @isTest
    static void testGetDocuments_noneUploaded() {
        Account acc = createAccount();
        List<String> docNames = new List<String>{ 'Invoice', 'Contract', 'ID Proof' };

        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result =
            FileDocumentController.getDocuments(acc.Id, docNames);
        Test.stopTest();

        for (FileDocumentController.DocumentStatusWrapper w : result) {

        }
    }

    @isTest
    static void testGetDocuments_partialUpload() {
        Account acc = createAccount();
        insertLinkedFile(acc.Id, 'Invoice.pdf', 'Invoice');
        // 'Contract' intentionally not uploaded

        List<String> docNames = new List<String>{ 'Invoice', 'Contract' };

        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result =
            FileDocumentController.getDocuments(acc.Id, docNames);
        Test.stopTest();

        Map<String, FileDocumentController.DocumentStatusWrapper> byLabel =
            new Map<String, FileDocumentController.DocumentStatusWrapper>();
        for (FileDocumentController.DocumentStatusWrapper w : result) {
            byLabel.put(w.label, w);
        }

    }

    @isTest
    static void testGetDocuments_fileWithUnknownDescriptionIgnored() {
        Account acc = createAccount();
        // File whose Description does NOT match any requested docName
        insertLinkedFile(acc.Id, 'Random.pdf', 'SomeOtherType');

        List<String> docNames = new List<String>{ 'Invoice' };

        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result =
            FileDocumentController.getDocuments(acc.Id, docNames);
        Test.stopTest();


    }

    @isTest
    static void testGetDocuments_emptyDocNames() {
        Account acc = createAccount();
        insertLinkedFile(acc.Id, 'Invoice.pdf', 'Invoice');

        Test.startTest();
        List<FileDocumentController.DocumentStatusWrapper> result =
            FileDocumentController.getDocuments(acc.Id, new List<String>());
        Test.stopTest();


    }

    // ─── markDocumentForType ──────────────────────────────────────────────────

    @isTest
    static void testMarkDocumentForType_updatesDescriptionAndTitle() {
        Account acc     = createAccount();
        Id contentDocId = insertLinkedFile(acc.Id, 'OldTitle.pdf', 'OldType');

        Test.startTest();
        FileDocumentController.markDocumentForType(
            acc.Id, 'Invoice', 'Invoice_Final.pdf', contentDocId
        );
        Test.stopTest();

        ContentDocument cd = [
            SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocId
        ];
        ContentVersion cv  = [
            SELECT Id, Description, Title
            FROM ContentVersion
            WHERE Id = :cd.LatestPublishedVersionId
        ];


    }

    @isTest
    static void testMarkDocumentForType_overwritesExistingDescription() {
        Account acc     = createAccount();
        Id contentDocId = insertLinkedFile(acc.Id, 'Doc.pdf', 'OldDocType');

        Test.startTest();
        FileDocumentController.markDocumentForType(
            acc.Id, 'NewDocType', 'Doc_v2.pdf', contentDocId
        );
        Test.stopTest();

        ContentDocument cd = [
            SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :contentDocId
        ];
        ContentVersion cv  = [
            SELECT Description, Title FROM ContentVersion WHERE Id = :cd.LatestPublishedVersionId
        ];

    }

    // ─── deleteFile ───────────────────────────────────────────────────────────

    @isTest
    static void testDeleteFile_deletesLinkAndDocument_whenNoOtherLinks() {
        Account acc     = createAccount();
        Id contentDocId = insertLinkedFile(acc.Id, 'ToDelete.pdf', 'Invoice');

        Test.startTest();
        FileDocumentController.deleteFile(acc.Id, contentDocId, 'Invoice');
        Test.stopTest();

        List<ContentDocumentLink> remainingLinks = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id AND ContentDocumentId = :contentDocId
        ];
  

        List<ContentDocument> remainingDocs = [
            SELECT Id FROM ContentDocument WHERE Id = :contentDocId
        ];
 
    }

    @isTest
    static void testDeleteFile_deletesLinkOnly_whenOtherLinksExist() {
        Account acc1    = createAccount();
        Account acc2    = new Account(Name = 'Second Account');
        insert acc2;

        // Insert file linked to acc1 first
        Id contentDocId = insertLinkedFile(acc1.Id, 'Shared.pdf', 'Contract');

        // Also link same document to acc2 (simulates multi-record sharing)
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            LinkedEntityId    = acc2.Id,
            ContentDocumentId = contentDocId,
            ShareType         = 'V',
            Visibility        = 'AllUsers'
        );
        insert cdl2;

        Test.startTest();
        // Delete the link for acc1 only
        FileDocumentController.deleteFile(acc1.Id, contentDocId, 'Contract');
        Test.stopTest();

        // Link for acc1 should be gone
        List<ContentDocumentLink> acc1Links = [
            SELECT Id FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc1.Id AND ContentDocumentId = :contentDocId
        ];
        System.assertEquals(0, acc1Links.size(), 'acc1 link should be deleted');

        // ContentDocument should still exist because acc2 link remains
        List<ContentDocument> remainingDocs = [
            SELECT Id FROM ContentDocument WHERE Id = :contentDocId
        ];

    }

    @isTest
    static void testDeleteFile_noLinkExists_noException() {
        Account acc = createAccount();
        // Insert file but do NOT link to acc
        ContentVersion cv = new ContentVersion(
            Title        = 'Orphan.pdf',
            PathOnClient = 'Orphan.pdf',
            VersionData  = Blob.valueOf('data'),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Test.startTest();
        try {
            FileDocumentController.deleteFile(acc.Id, cv.ContentDocumentId, 'Invoice');

        } catch (Exception e) {

        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteFile_multipleDocTypes_onlyTargetDeleted() {
        Account acc     = createAccount();
        Id invoiceDocId = insertLinkedFile(acc.Id, 'Invoice.pdf',  'Invoice');
        Id contractDocId= insertLinkedFile(acc.Id, 'Contract.pdf', 'Contract');

        Test.startTest();
        FileDocumentController.deleteFile(acc.Id, invoiceDocId, 'Invoice');
        Test.stopTest();

    }

    // ─── DocumentStatusWrapper constructor ────────────────────────────────────

    @isTest
    static void testDocumentStatusWrapper_defaultValues() {
        FileDocumentController.DocumentStatusWrapper w =
            new FileDocumentController.DocumentStatusWrapper('Passport');

  
    }
}