import '../model/team_post_model.dart';
import '../services/team_service.dart';

class CreateTeamPostController {
  final TeamService _teamService = TeamService();

  Future<String> submitTeamPost(TeamPostModel post) async {
    final docRef = await _teamService.createTeamPost(post);
    return docRef.id;
  }
}