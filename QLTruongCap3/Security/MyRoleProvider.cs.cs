using QLTruongCap3.Models;
using System;
using System.Linq;
using System.Web.Security;

namespace QLTruongC3.Security
{
    public class MyRoleProvider : RoleProvider
    {
        public override string[] GetRolesForUser(string username)
        {
            using (var db = new QLTRUONGC3Entities())
            {
                var user = db.TAIKHOAN.FirstOrDefault(x => x.USERNAME == username);
                if (user != null && user.TINHTRANG == "Hoạt động")
                {
                    return new string[] { user.LOAI }; // Trả về "Admin", "GV", hoặc "HS"
                }
            }
            return new string[] { };
        }

        public override bool IsUserInRole(string username, string roleName)
        {
            var roles = GetRolesForUser(username);
            return roles.Contains(roleName);
        }

        // Các hàm không dùng đến (để mặc định throw exception hoặc return null)
        public override string ApplicationName { get => throw new NotImplementedException(); set => throw new NotImplementedException(); }
        public override void AddUsersToRoles(string[] usernames, string[] roleNames) => throw new NotImplementedException();
        public override void CreateRole(string roleName) => throw new NotImplementedException();
        public override bool DeleteRole(string roleName, bool throwOnPopulatedRole) => throw new NotImplementedException();
        public override string[] FindUsersInRole(string roleName, string usernameToMatch) => throw new NotImplementedException();
        public override string[] GetAllRoles() => throw new NotImplementedException();
        public override string[] GetUsersInRole(string roleName) => throw new NotImplementedException();
        public override void RemoveUsersFromRoles(string[] usernames, string[] roleNames) => throw new NotImplementedException();
        public override bool RoleExists(string roleName) => throw new NotImplementedException();
    }
}
