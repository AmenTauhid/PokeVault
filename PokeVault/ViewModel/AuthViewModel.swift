import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User? = Auth.auth().currentUser
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userProfileComplete = false
    
    private let auth = Auth.auth()
    
    init() {
        // Check if user is already logged in
        if auth.currentUser != nil {
            isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                // Successfully signed in
                self.setupUserAfterLogin { success in
                    DispatchQueue.main.async {
                        if success {
                            self.isAuthenticated = true
                        } else {
                            self.errorMessage = "Failed to set up user profile"
                        }
                    }
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                // Update user profile with name
                let changeRequest = self.auth.currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges { error in
                    if let error = error {
                        print("Error updating user profile: \(error.localizedDescription)")
                    }
                    
                    // Set up user in Firestore
                    self.setupUserAfterLogin { success in
                        DispatchQueue.main.async {
                            if success {
                                self.isAuthenticated = true
                                completion(true)
                            } else {
                                self.errorMessage = "Failed to set up user profile"
                                completion(false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetPassword(email: String) {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        auth.sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                }
                // Don't set success message to maintain privacy
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            isAuthenticated = false
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
    
    // Setup user in Firestore after login or signup
    func setupUserAfterLogin(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("No user is logged in")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(user.uid)
        
        // Create or update the user document
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "name": user.displayName ?? user.email?.components(separatedBy: "@").first ?? "User",
            "userId": user.uid,
            "lastLogin": FieldValue.serverTimestamp(),
            "searchableEmail": (user.email ?? "").lowercased(), // For easier searching
            "searchableName": (user.displayName ?? "").lowercased() // For easier searching
        ]
        
        userDocRef.setData(userData, merge: true) { error in
            if let error = error {
                print("Error setting up user document: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Create the chats subcollection with a placeholder document
            FirebaseService.shared.createChatCollection(userId: user.uid) { success in
                if success {
                    print("User setup complete with chats collection")
                    completion(true)
                } else {
                    print("Failed to create chats collection")
                    completion(false)
                }
            }
        }
    }
    
    // Call this to check if user is fully set up
    func userDidLogin() {
        setupUserAfterLogin { success in
            DispatchQueue.main.async {
                if success {
                    // Proceed to main app
                    print("User setup complete, ready to use the app")
                    self.userProfileComplete = true
                } else {
                    // Handle error
                    print("Failed to complete user setup")
                    self.userProfileComplete = false
                }
            }
        }
    }
}
