import React from 'react';
import { Link } from 'react-router-dom';
import './ClansPage.css';
import Page from './Page';
import DynamicComponent from '../DynamicComponent';
import PlayerWidget from '../components/PlayerWidget';
import ClanTile from '../components/ClanTile';
import endpoints from '../endpoints';
import _ from 'lodash';

class ClansPage extends DynamicComponent {
    getEndpoints() {
        return {"clans": endpoints.clans};
    }

    render() {
        if (!this.isAllDynamicDataLoaded())
            return this.getLoadingDynamicContent();

        let clansData = _.sortBy(this.getDynamicData("clans"), (c) => -c.members.length);
        let clansTiles = [];

        for (let i=0; i < clansData.length; ++i) {
            let clan = clansData[i];
            clansTiles.push(<ClanTile key={i} clantag={clan.clan} />);
        }

        return (
            <div className="ClansPage">
                <Page title="Clans">
                    {clansTiles}
                </Page>
            </div>
        );
    }
}
export default ClansPage;
