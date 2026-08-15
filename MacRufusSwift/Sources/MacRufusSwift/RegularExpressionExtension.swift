import Foundation

/*
Credit: Paul Hudson started these ideas of extending NSRegularExpression with easier methods.  
  I just added a few more to make it easier to use in my code.  See article
  on https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift
*/
extension NSRegularExpression 
{
  ///////////////////////////////////////////////////////////////
  /// Static Class Methods
  /*
  Instead of require the caller to create NSRegularExpression and Range instances, 
  this function will create for you.  If no match is found, it will return an empty array.
  Internally, it will call matchesOfRegex(regex:in:options:) to do the actual work.
  Arguments:
    pattern: The String form regex pattern to match against without the slashes /___/ at front and end.
    text: The input text to search for matches.
    options: Optional NSRegularExpression.Options to customize the regex behavior (default is empty).  
      You can specify options like .caseInsensitive, .dotMatchesLineSeparators, etc.
  @returns: An array of strings that correspond to the whole matching string (index 0) 
    and any capture groups (index 1 and onwards) for the given pattern in the provided text.
  */
  static func matchesOfString(pattern: String, in text: String, options: NSRegularExpression.Options = []) -> [String] { 
    let regex = try!NSRegularExpression(pattern: pattern, options: options)
    return NSRegularExpression.matchesOfRegex(regex: regex, in: text, options: options)
  }

  /*
  Instead of require the caller to create Range instance, this function will create for you.  If no match is found, it will return an empty array.
  Arguments:
    pattern: The String form regex pattern to match against without the slashes /___/ at front and end.
    text: The input text to search for matches.
    options: Optional NSRegularExpression.Options to customize the regex behavior (default is empty).  
      You can specify options like .caseInsensitive, .dotMatchesLineSeparators, etc.
  @returns: An array of strings that correspond to the whole matching string (index 0) 
    and any capture groups (index 1 and onwards) for the given pattern in the provided text.
  */
  static func matchesOfRegex(regex: NSRegularExpression, in text: String, options: NSRegularExpression.Options = []) -> [String] { 
    var results : [String] = []
    if let match: NSTextCheckingResult = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) 
    {
      for i in 0..<match.numberOfRanges {
        if let range = Range(match.range(at: i), in: text) {
          let matchedString = String(text[range])
          results.append(matchedString)
        }
      }
    }
    return results
  }

  ///////////////////////////////////////////////////////////////
  /// Instance Methods
  /*
  Instead of require the caller to create Range instance, this function will create for you.  If no match is found, it will return an empty array.
  Different than matches because this returns the first match only, not all matches.  Internally, it will call matchesOfRegex(regex:in:options:) to do the actual work.
  Arguments:
    text: The input text to search for matches.
    options: Optional NSRegularExpression.Options to customize the regex behavior (default is empty).  
      You can specify options like .caseInsensitive, .dotMatchesLineSeparators, etc.
  @returns: An array of strings that correspond to the whole matching string (index 0) 
    and any capture groups (index 1 and onwards) for the given pattern in the provided text.
  */
  func fetchMatches(in text: String, options: NSRegularExpression.Options = []) -> [String] {
    return NSRegularExpression.matchesOfRegex(regex: self, in: text, options: options)
  }

}

/*
*/
extension String {
  ///////////////////////////////////////////////////////////////
  /// Static Class Methods
  /*
  Left-hand side string is the input text, right-hand side string is the regex pattern.  If the pattern matches, return true; otherwise false.
  Because of the limitation of Swift's syntax for function operator, cannot use =~ operator like in Perl or Ruby.  Instead, use ~= operator.
  For example:
    "hat" ~= "[a-z]at"
  Arguments:
    lhs: The input text to search for matches.
    rhs: The String form regex pattern to match against without the slashes /___/ at front and end.
  @returns: true if the regex pattern matches the input text; false otherwise

  Credit: Paul Hudson on https://www.hackingwithswift.com/articles/108/how-to-use-regular-expressions-in-swift
  */
  static func ~= (lhs: String, rhs: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: rhs) else { return false }
    let range = NSRange(location: 0, length: lhs.utf16.count)
    return regex.firstMatch(in: lhs, options: [], range: range) != nil
  }

  ///////////////////////////////////////////////////////////////
  /// Instance Methods
  /*
  Instead of require the caller to create NSRegularExpression and Range instances, this function will create for you.  If no match is found, it will return an empty array.
  Arguments:
    pattern: The String form regex pattern to match against without the slashes /___/ at front and end.
    options: Optional NSRegularExpression.Options to customize the regex behavior (default is empty).  
      You can specify options like .caseInsensitive, .dotMatchesLineSeparators, etc.
  @returns: An array of strings that correspond to the whole matching string (index 0) and any capture groups (index 1 and onwards) for the given pattern in the provided text.
  */
  func matches(pattern: String, options: NSRegularExpression.Options = []) -> [String] {
    return NSRegularExpression.matchesOfString(pattern: pattern, in: self, options: options)
  }
}