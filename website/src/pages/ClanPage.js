import React from 'react';
import './ClanPage.css';
import Page from './Page';
import DynamicComponent from '../DynamicComponent';
import PlayerWidget from '../components/PlayerWidget';
import endpoints from '../endpoints';

class ClanPage extends DynamicComponent {
    getEndpoints() {
        return {"clan": endpoints.clan(this.props.match.params.clantag)};
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return this.getLoadingDynamicContent();

        let clantag = this.props.match.params.clantag
        let clanData = this.getDynamicData('clan');

        let badgeURL = "clan-badge.svg";
        if (clanData.badgeURL) {
            badgeURL = clanData.badgeURL;
        }
        let badge = <img src={badgeURL} alt={clantag + " badge"}/>;

        let forumLink = "No link set";
        if (clanData.forumURL) {
            forumLink = <a href={clanData.forumURL}>{clanData.forumURL}</a>;
        }

        let leaderWidget = "No leader set";
        if (clanData.leader) {
            // The leader could be set but hasn't actually played a match yet so they're not in the database
            if (this.isLeaderInRoster(clanData.leader, clanData.members))
                leaderWidget = <PlayerWidget username={clanData.leader} />;
            else
                leaderWidget = clanData.leader;
        }

        let rosterWidgets = [];
        for (let i=0; i < clanData.members.length; ++i) {
            let username = clanData.members[i].username;

            if (username !== clanData.leader)
                rosterWidgets.push(<PlayerWidget key={i} username={username} />);
        }

        let membersString = (clanData.members.length === 1 ? "member" : "members");

        return (
            <div className="ClanPage">
                <Page title="Clan">
                    <div className="_topRow">
                        <div className="_infoBox">
                            <div className="_clantag">
                                {clantag}
                            </div>
                            <div className="box _forumLink">
                                <div className="_box_label">Forum link</div>
                                {forumLink}
                            </div>
                            <div className="box _leader">
                                <div className="_box_label">Leader</div>
                                {leaderWidget}
                            </div>
                        </div>
                        <div className="_badgeBox">
                            {badge}
                        </div>
                    </div>
                    <div className="box _roster">
                        <div className="_box_label">Roster - {clanData.members.length + " " + membersString}</div>
                        <div className="_rosterWidgets">
                            {rosterWidgets}
                        </div>

                    </div>
                </Page>
            </div>
        );
    }

    isLeaderInRoster(leader, roster) {
        for (let player of roster) {
            if (player.username === leader)
                return true;
        }
        return false;
    }
}
export default ClanPage;
