trigger RenameUploadedFiles on ContentVersion (before insert) {
    for (ContentVersion cv : Trigger.new) {
        if (cv.Title != null && cv.PathOnClient != null) {
            if (!cv.Title.contains('_')) {
                cv.Title = cv.Title + '_' + cv.PathOnClient;
            }
        }
    }
}