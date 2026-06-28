# Status: 002-fix-camera-initial-position

status: done

## Commit / PR
PR #206, squash commit 8fab527 — fix(map-quiz): stop using .automatic MapCameraPosition in river/mountain/sea quizzes

## Changes
- Hanahuac/Views/Quiz/MapQuiz/MapQuizView.swift: .automatic → .region(MKCoordinateRegion())
- Hanahuac/Views/Quiz/MapQuiz/MapLearningQuizView.swift: .automatic → .region(MKCoordinateRegion())
