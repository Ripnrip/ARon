//
//  WorkoutTableViewCell.swift
//  ARON
//
//  Created by Gurinder Singh on 9/25/21.
//

import UIKit

class WorkoutTableViewCell: UITableViewCell {

    @IBOutlet weak var WorkoutImageView: UIImageView!
    @IBOutlet weak var BeginWorkoutButton: UIButton!
    @IBOutlet weak var WorkoutTitle: UITextField!
    
    var workoutClosure: (() -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func beginWorkout(_ sender: Any) {
        if let action = workoutClosure {
            action()
        }
    }
    
}
