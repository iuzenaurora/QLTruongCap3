using QLTruongCap3.Models;
using System.Linq;
using System.Web.Mvc;
using System.Web.Security;

namespace QLTruongC3.Controllers
{
    public class AccountController : Controller
    {
        private QLTRUONGC3Entities db = new QLTRUONGC3Entities();

        [HttpGet]
        public ActionResult Login()
        {
            if (User.Identity.IsAuthenticated) return RedirectToDefault();
            return View();
        }

        [HttpPost]
        public ActionResult Login(string username, string password)
        {
            var user = db.TAIKHOAN.FirstOrDefault(u => u.USERNAME == username && u.PASSWORD == password);

            if (user != null)
            {
                if (user.TINHTRANG != "Hoạt động")
                {
                    ViewBag.Error = "Tài khoản đang bị khóa!";
                    return View();
                }

                // Tạo cookie đăng nhập
                FormsAuthentication.SetAuthCookie(username, false);

                // Điều hướng
                if (user.LOAI == "Admin") return RedirectToAction("Index", "Admin");
                if (user.LOAI == "GV") return RedirectToAction("Index", "Teacher");
                if (user.LOAI == "HS") return RedirectToAction("Index", "Student");
            }

            ViewBag.Error = "Sai tên đăng nhập hoặc mật khẩu!";
            return View();
        }

        public ActionResult Logout()
        {
            FormsAuthentication.SignOut();
            return RedirectToAction("Login");
        }

        private ActionResult RedirectToDefault()
        {
            if (User.IsInRole("Admin")) return RedirectToAction("Index", "Admin");
            if (User.IsInRole("GV")) return RedirectToAction("Index", "Teacher");
            if (User.IsInRole("HS")) return RedirectToAction("Index", "Student");
            return RedirectToAction("Login");
        }
    }
}
