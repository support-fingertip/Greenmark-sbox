({
    filterUsers : function(component, searchKey) {
        var allUsers = component.get("v.userList");
        if(!searchKey || searchKey.trim() === "") {
            component.set("v.filteredUserList", allUsers);
            return;
        }
        
        var filteredUsers = allUsers.filter(function(user) {
            return user.Name.toLowerCase().includes(searchKey.toLowerCase());
        });
        component.set("v.filteredUserList", filteredUsers);
    }
})