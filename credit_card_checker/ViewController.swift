//
//  ViewController.swift
//  credit_card_checker
//
//  Created by Vismay Igur on 6/26/23.
//

import Foundation
import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var outputLabel: UILabel!
    @IBOutlet weak var cardTypeImageView: UIImageView!
    
    var jsonData: [String: Any] = [:]

    //initial state of app
    override func viewDidLoad() {
        super.viewDidLoad()
        inputField.delegate = self
        outputLabel.isHidden = true
        cardTypeImageView.isHidden = true
    }
    
    //struct created card details, part of api, doesn't affect rest of code, leave it
    struct CardDetails: Codable {
        let bank: String
        let bin: String
        let country: String
    }
    
    //when validate button is clicked, this function runs
    @IBAction func runValidation(_ sender: UIButton) {
        if let card_number = inputField.text
        {
            let api_key = "PQnvNLi7EM85WrKRC8SvDamJojSPHIUH"
            
            let validationResult = isValidNumber(card_number)
            
            //outputLabel.text = validationResult
            //outputLabel.isHidden = false
            
            
            getCardDetailsFromBin(cardNumber: card_number, apiKey: api_key) { result in
                switch result {
                case .success(let cardDetails):
                    let cardCountry = cardDetails.country
                case .failure(let error):
                    // Handle the API request failure or error appropriately.
                    print("Error fetching card details: \(error)")
                }
            }
            
            if (validationResult == "Valid Card")
            {
                displayJSONInPopup(json: jsonData)
            }
            else
            {
                let informationMessage = validationResult
                showPopup(withMessage: informationMessage)
            }
            
        }
        else
        {
            return
        }
        
    }
     
    //function that updates textbox/card number in real time.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let userInput = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
        //let validationResult = isValidNumber(userInput)
        let cardType = detectCardType(cardNumber: userInput)
        let imageName = cardType
        if let image = UIImage(named: imageName) {
            cardTypeImageView.image = image
        } else {
            cardTypeImageView.image = UIImage(named: "defaultCardImage")
        }
        
        cardTypeImageView.isHidden = false

        return true
    }
    
    func getCardDetailsFromBin(cardNumber: String, apiKey: String, completion: @escaping (Result<CardDetails, Error>) -> Void)
    {
        let bin = String(cardNumber.prefix(6))
        var urlRequest = URLRequest(url: URL(string: "https://api.apilayer.com/bincheck/" + bin)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
 
        urlRequest.httpMethod = "GET"
        urlRequest.addValue(apiKey, forHTTPHeaderField: "apikey")
       

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else { return }
            if let httpResponse = response as? HTTPURLResponse {
                   // Get the status code
                   let statusCode = httpResponse.statusCode
                   print("Status Code: \(statusCode)")
                   
                   // Get the headers
                   let headers = httpResponse.allHeaderFields
                   print("Response Headers: \(headers)")
               }
            
            if let data = data {
                do {
                    self.jsonData = try JSONSerialization.jsonObject(with: data, options: []) as! [String : Any]
                }
                catch {
                    print("JSON Parsing Error: \(error)")
                    // Handle parsing error
                }
            }
            
        }.resume()
    }
    
    //function that creates popups
    func showPopup(withMessage message: String) {
        let alertController = UIAlertController(title: "Information", message: message, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }
    
    //function that chooses specific data from json to be shown
    func formatDataForPopup() -> String {
            // Choose specific keys from the JSON data and format them as needed
            let bin = jsonData["bin"] as? String ?? ""
            let country = jsonData["country"] as? String ?? ""
            let bankName = jsonData["bank_name"] as? String ?? ""

            // Create the formatted string with the chosen information
            let formattedString = "Bank Identification Number: \(bin)\nCountry: \(country)\nBank: \(bankName)"
            return formattedString
        }
    
    //function that displays json data in popup
    func displayJSONInPopup(json: [String: Any]) {
        
        let popupContent = formatDataForPopup()
            
        // Create a popup view or alert controller to display the JSON string
        let alertController = UIAlertController(title: "Card Information", message: popupContent, preferredStyle: .alert)
        
        // Add an "OK" button to dismiss the popup
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
                
        // Present the popup
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    //function to detect card type based on MMI
    func detectCardType(cardNumber: String) -> String {
        let cardTypes: [String: String] = [
            "4": "Visa",
            "5": "Mastercard",
            "34": "Amex",
            "37": "Amex",
            "6": "Discover"
        ]
        
        for (prefix, type) in cardTypes {
            if cardNumber.hasPrefix(prefix) {
                return type
            }
        }
        return "Unknown"
    }
    
    //Luhn's algorithm for credit card validity
    func isValidNumber(_ card: String) -> String {
        var stack = [Int]()
        var sum = 0
        var count = 1
        var isValid = false
        var ret = ""

        for char in card {
            stack.append(Int(String(char))!)
        }

        for j in stride(from: stack.count - 2, through: 0, by: -2) {
            stack[j] *= 2
        }

        while !stack.isEmpty {
            if count % 2 == 1 {
                sum += stack.removeLast()
                count += 1
            } else {
                if stack.last! < 9 {
                    sum += stack.removeLast()
                    count += 1
                } else {
                    let first = stack.last! / 10
                    let second = stack.last! % 10
                    sum += first
                    sum += second
                    stack.removeLast()
                    count += 1
                }
            }
        }

        if sum % 10 == 0 {
            isValid = true
        }

        if isValid {
            ret += "Valid Card"
        } else {
            ret += "Invalid Card"
        }

        return ret
    }
    
}


