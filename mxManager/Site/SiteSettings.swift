//
//  SiteSettings.swift
//  mxManager
//
//  Created by Василий Наумкин on 18.12.14.
//  Copyright (c) 2014 bezumkin. All rights reserved.
//

import UIKit

class SiteSettings: DefaultView, UITextFieldDelegate, UITextViewDelegate {

	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var navigationBar: UINavigationBar!
	@IBOutlet var btnSave: UIBarButtonItem!
	@IBOutlet var btnCancel: UIBarButtonItem!

	// Main fields
	@IBOutlet var fieldSite: UITextField!
	@IBOutlet var fieldManager: UITextField!
	@IBOutlet var fieldUser: UITextField!
	@IBOutlet var fieldPassword: UITextField!

	// Basic authentication
	@IBOutlet var fieldBaseAuth: UISwitch!
	@IBOutlet var fieldBaseUser: UITextField!
	@IBOutlet var fieldBasePassword: UITextField!
	@IBOutlet var labelBaseUser: UILabel!
	@IBOutlet var labelBasePassword: UILabel!

	var keyboardHeight: CGFloat = 0
	var disableCancel = false

	override func viewDidLoad() {
		super.viewDidLoad()
		self.addSaveButton()
		self.fixTopOffset(UIApplication.sharedApplication().statusBarOrientation.isLandscape)

		if self.data.count != 0 {
			self.setFormValues(self.data)
			self.navigationItem.title = Utils.lexicon("site_settings")
		}
		else {
			self.navigationItem.title = Utils.lexicon("new_site")
			if self.disableCancel {
				self.btnCancel.enabled = false
			}
		}
	}

	override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
		self.fixTopOffset(toInterfaceOrientation.isLandscape)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SiteSettings.onKeyboadWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SiteSettings.onKeyboadWillShow(_:)), name: UIKeyboardWillChangeFrameNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SiteSettings.onKeyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillChangeFrameNotification, object: nil)
		NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
	}

	func setFormValues(data: NSDictionary) {
		if data["site"] != nil {
			self.fieldSite.text = data["site"] as! NSString as String
		}
		if data["manager"] != nil {
			self.fieldManager.text = data["manager"] as! NSString as String
		}
		if data["user"] != nil {
			self.fieldUser.text = data["user"] as! NSString as String
		}
		if data["password"] != nil {
			self.fieldPassword.text = data["password"] as! NSString as String
		}
		if data["base_auth"] != nil && data["base_auth"] as! Bool {
			self.fieldBaseAuth.setOn(true, animated: false)
			if data["base_user"] != nil {
				self.fieldBaseUser.text = data["base_user"] as! NSString as String
				self.fieldBaseUser.hidden = false
				self.fieldBaseUser.enabled = true
			}
			if data["base_password"] != nil {
				self.fieldBasePassword.text = data["base_password"] as! NSString as String
				self.fieldBasePassword.hidden = false
				self.fieldBasePassword.enabled = true
			}
		}
	}

	func checkForm() -> Bool {
		var hasError = false

		// Main fields
		if self.fieldSite.text == "" {
			hasError = true
			self.fieldSite.markError(true)
		}
		else {
			self.fieldSite.markError(false)
		}

		if self.fieldManager.text == "" || !Regex("\\w{1,}\\.\\w{2,}").test(self.fieldManager.text!) {
			hasError = true
			self.fieldManager.markError(true)
		}
		else {
			if !Regex("^http(s|)://").test(self.fieldManager.text!) {
				self.fieldManager.text = "http://" + self.fieldManager.text!
			}
			if !Regex("/$").test(self.fieldManager.text!) {
				self.fieldManager.text = self.fieldManager.text! + "/"
			}
			self.fieldManager.markError(false)
		}

		if self.fieldUser.text == "" {
			hasError = true
			self.fieldUser.markError(true)
		}
		else {
			self.fieldUser.markError(false)
		}

		if self.fieldPassword.text == "" {
			hasError = true
			self.fieldPassword.markError(true)
		}
		else {
			self.fieldPassword.markError(false)
		}

		// Basic authentication
		if self.fieldBaseAuth.on {
			if self.fieldBaseUser.text == "" {
				hasError = true
				self.fieldBaseUser.markError(true)
			}
			else {
				self.fieldBaseUser.markError(false)
			}

			if self.fieldBasePassword.text == "" {
				hasError = true
				self.fieldBasePassword.markError(true)
			}
			else {
				self.fieldBasePassword.markError(false)
			}
		}

		return hasError == false
	}

	@IBAction func submitForm(sender: UIBarButtonItem?) {
		if !self.checkForm() {
			return
		}
		self.view.endEditing(true)

		let site = [
				"site": self.fieldSite.text!,
				"manager": self.fieldManager.text!,
				"user": self.fieldUser.text!,
				"password": self.fieldPassword.text!,
				"base_auth": self.fieldBaseAuth.on,
				"base_user": self.fieldBaseAuth.on
					? self.fieldBaseUser.text!
					: String(""),
				"base_password": self.fieldBaseAuth.on
					? self.fieldBasePassword.text!
					: String(""),
				"key": self.data["key"] != nil
					? self.data["key"] as! String
					: NSUUID().UUIDString,
		] as NSMutableDictionary

		let sites = Utils.getSites()
		if sites.count > 0 {
			for existing_site in sites {
				// Check for existing site with the same name or url
				let s = existing_site["site"] as! NSString
				let m = existing_site["manager"] as! NSString
				let s2 = self.fieldSite.text
				let m2 = self.fieldManager.text
				var message = ""
				if s.lowercaseString == s2!.lowercaseString && site["key"] as! String != existing_site["key"] as! String {
					message = "site_err_site_ae"
				}
				else if m.lowercaseString == m2!.lowercaseString && site["key"] as! String != existing_site["key"] as! String {
					message = "site_err_manager_ae"
				}
				if message != "" {
					Utils.alert("error", message: message, view: self)
					return
				}
			}
		}

		Utils.showSpinner(self.view)
		self.btnSave.enabled = false
		self.btnCancel.enabled = false
		self.data = site
		self.Request([
				"mx_action": "auth",
				"username": site["user"] as! String,
				"password": site["password"] as! String,
			], success: {
			data in
				if let tmp = data["data"] as? NSDictionary {
					if tmp["site_url"] != nil {
						site["site_url"] = tmp["site_url"] as? String
					}
					if tmp["version"] != nil {
						site["version"] = tmp["version"] as? String
					}
				}
				if Utils.addSite(site["key"] as! String, site:site) {
					self.closePopup()
				}
				Utils.hideSpinner(self.view)
			}, failure: {
			data in
				Utils.alert("", message: data["message"] as! String, view: self)
				self.btnSave.enabled = true
				self.btnCancel.enabled = !self.disableCancel
				Utils.hideSpinner(self.view)
		})
	}

	@IBAction func closePopup() {
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	func fixTopOffset(landscape: Bool) {
		let constraints = self.navigationBar.constraints
		let constraint = constraints[0] 

		constraint.constant = landscape
				? 32.0
				: 64.0
	}

	@IBAction func switchBaseAuth(sender: UISwitch) {
		let enabled = sender.on as Bool

		self.fieldBaseUser.hidden = !enabled
		self.fieldBaseUser.enabled = enabled
		self.fieldBasePassword.hidden = !enabled
		self.fieldBasePassword.enabled = enabled
		self.labelBaseUser.hidden = !enabled
		self.labelBasePassword.hidden = !enabled
	}

	func onKeyboadWillShow(notification: NSNotification) {
		let info: NSDictionary = notification.userInfo!
		if let rectValue = info[UIKeyboardFrameBeginUserInfoKey] as? NSValue {
			let kbSize: CGRect = rectValue.CGRectValue()
			if self.keyboardHeight != kbSize.size.height {
				self.keyboardHeight = kbSize.size.height

				var contentInset: UIEdgeInsets = self.scrollView.contentInset
				contentInset.bottom = kbSize.size.height
				self.scrollView.contentInset = contentInset
				dispatch_async(dispatch_get_main_queue()) {
					self.addHideKeyboardButton()
				}
			}
		}
	}

	func onKeyboardWillHide(notification: NSNotification) {
		if self.keyboardHeight != 0 {
			self.keyboardHeight = 0
			let contentInsets: UIEdgeInsets = UIEdgeInsetsZero
			self.scrollView.contentInset = contentInsets
			self.scrollView.scrollIndicatorInsets = contentInsets
			dispatch_async(dispatch_get_main_queue()) {
				self.addSaveButton()
			}
		}
	}

	func addSaveButton() {
		let icon = UIImage.init(named: "icon-check")
		let btn = UIBarButtonItem.init(image: icon, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SiteSettings.submitForm(_:)))
		btn.tintColor = Colors.defaultText()
		self.navigationItem.setRightBarButtonItem(btn, animated: false)
	}

	func addHideKeyboardButton() {
		let icon = UIImage.init(named: "icon-keyboard-hide")
		let btn = UIBarButtonItem.init(image: icon, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(SiteSettings.finishEdit(_:)))
		btn.tintColor = Colors.defaultText()
		self.navigationItem.setRightBarButtonItem(btn, animated: false)
	}

	@IBAction func finishEdit(sender: UITextField?) {
		self.view.endEditing(true)
	}

}
